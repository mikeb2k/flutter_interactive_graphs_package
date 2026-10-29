import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:interactive_graphs/src/layout/layout_config.dart';
import 'package:interactive_graphs/src/model/graph.dart';
import 'package:interactive_graphs/src/model/graph_node.dart';

/// Force-directed layout (spring embedder).
///
/// Nodes repel each other like charges, edges act as springs and a weak centering force keeps the
/// graph from drifting. Velocity is capped by a cooling schedule over
/// [ForceDirectedLayoutConfig.iterations]. Repulsion is cut off beyond a few node sizes, and above
/// a few hundred nodes a spatial grid skips exactly the pairs the cutoff discards.
///
/// References: Fruchterman & Reingold (1991), "Graph Drawing by Force-Directed Placement";
/// Eades (1984), "A Heuristic for Graph Drawing".
abstract final class ForceDirectedLayout {
  // Repulsion is ignored beyond this multiple of the pair's minimum distance
  static const double _maxRepulsionDistanceFactor = 3;

  // Minimum pair separation as a fraction of the two nodes' combined average size
  static const double _minDistanceFactor = 0.9;

  // Below this node count the grid costs more than it saves
  static const int _gridMinNodeCount = 128;

  // Cell width as a fraction of the largest interaction radius
  static const double _gridCellsPerRadius = 4;

  // Cell count ceiling as a multiple of the node count
  static const double _maxCellsPerNode = 8;

  // Velocity ceiling at the last iteration as a fraction of the initial one
  static const double _finalCoolingFactor = 0.1;

  // Cancellation polling interval, in nodes
  static const int _cancellationCheckInterval = 256;

  // Room the bounds grant each node, as a multiple of its average size
  static const double _nodeRoomFactor = 2.5;

  static const double _maxVelocity = 10;
  static const double _centeringStrength = 0.01;

  /// Factor by which the simulation bounds exceed the canvas: 1 while the graph fits, growing with
  /// the node count beyond that. The viewer's initial fit zooms out to match.
  static double boundsScale(int nodeCount, double averageNodeSize, double width, double height) {
    final room = averageNodeSize * _nodeRoomFactor;
    return math.max(1, math.sqrt(nodeCount * room * room / (width * height)));
  }

  /// Size of [node] as the simulation sees it: the mean of its width and height, or [fallback].
  static double averageSize(GraphNode node, double fallback) {
    final size = node.size;
    return size == null ? fallback : (size.width + size.height) / 2;
  }

  /// Lays [graph] out. Returns [graph] unchanged while the canvas is unmeasured.
  ///
  /// [checkCancelled] is polled every iteration and every few hundred nodes within one.
  static Graph run(Graph graph, ForceDirectedLayoutConfig config, {void Function()? checkCancelled}) {
    final canvas = config.canvasSize;
    if (canvas.width <= 0 || canvas.height <= 0) return graph;
    final ids = graph.nodes.keys.toList();
    final n = ids.length;
    if (n == 0) return graph;
    final check = checkCancelled ?? () {};

    final index = {for (var i = 0; i < n; i++) ids[i]: i};
    final posX = Float64List(n);
    final posY = Float64List(n);
    final velX = Float64List(n);
    final velY = Float64List(n);
    final forceX = Float64List(n);
    final forceY = Float64List(n);
    final sizeAvg = Float64List(n);

    var sizeSum = 0.0;
    var sizeMax = 0.0;
    for (var i = 0; i < n; i++) {
      final s = averageSize(graph.nodes[ids[i]]!, GraphNode.defaultSize);
      sizeAvg[i] = s;
      sizeSum += s;
      sizeMax = math.max(sizeMax, s);
    }
    final avgNodeSize = sizeSum / n;

    final scale = boundsScale(n, avgNodeSize, canvas.width, canvas.height);
    final width = canvas.width * scale;
    final height = canvas.height * scale;

    // One spring per connected pair
    final springPairs = <(int, int)>{
      for (final edge in graph.edges) (index[edge.fromId]!, index[edge.toId]!),
    }.toList();

    final centerX = width / 2;
    final centerY = height / 2;
    final initialRadius = math.min(width, height) * 0.3;
    if (n == 1) {
      posX[0] = centerX;
      posY[0] = centerY;
    } else {
      for (var i = 0; i < n; i++) {
        final angle = i * 2 * math.pi / n;
        posX[i] = centerX + initialRadius * math.cos(angle);
        posY[i] = centerY + initialRadius * math.sin(angle);
      }
    }

    final repulsion = config.repulsionStrength;
    final extraRepulsion = repulsion * 0.5;
    final margin = avgNodeSize;
    final maxX = width - margin;
    final maxY = height - margin;

    // Spatial grid; below the threshold a single cell makes it the plain O(n²) loop
    final maxInteraction = 2 * sizeMax * _minDistanceFactor * _maxRepulsionDistanceFactor;
    final extentX = math.max(width, margin) + 1;
    final extentY = math.max(height, margin) + 1;
    final cellSize = n <= _gridMinNodeCount
        ? math.max(extentX, extentY)
        : math.max(
            math.max(maxInteraction / _gridCellsPerRadius, 1.0),
            math.sqrt(extentX * extentY / (_maxCellsPerNode * n)),
          );
    final cols = math.max(1, (extentX / cellSize).ceil());
    final rows = math.max(1, (extentY / cellSize).ceil());
    final cellCount = cols * rows;

    final cellRing = Int32List(n);
    for (var i = 0; i < n; i++) {
      final radius = (sizeAvg[i] + sizeMax) * _minDistanceFactor * _maxRepulsionDistanceFactor;
      cellRing[i] = (radius / cellSize).toInt() + 1;
    }

    final nodeCell = Int32List(n);
    final cellStart = Int32List(cellCount + 1);
    final cellCursor = Int32List(cellCount);
    final cellItems = Int32List(n);
    final gridPosX = Float64List(n);
    final gridPosY = Float64List(n);
    final gridSize = Float64List(n);
    final gridRing = Int32List(n);
    final gridCell = Int32List(n);
    final gridForceX = Float64List(n);
    final gridForceY = Float64List(n);

    final iterations = config.iterations;
    final coolingStep = iterations > 1 ? (1 - _finalCoolingFactor) / (iterations - 1) : 0.0;

    for (var iteration = 0; iteration < iterations; iteration++) {
      check();

      // Counting sort of the nodes into cells
      cellCursor.fillRange(0, cellCount, 0);
      for (var i = 0; i < n; i++) {
        final cx = (posX[i] / cellSize).toInt().clamp(0, cols - 1);
        final cy = (posY[i] / cellSize).toInt().clamp(0, rows - 1);
        final cell = cy * cols + cx;
        nodeCell[i] = cell;
        cellCursor[cell]++;
      }
      var offset = 0;
      for (var c = 0; c < cellCount; c++) {
        cellStart[c] = offset;
        offset += cellCursor[c];
        cellCursor[c] = cellStart[c];
      }
      cellStart[cellCount] = offset;
      for (var i = 0; i < n; i++) {
        final cell = nodeCell[i];
        final slot = cellCursor[cell]++;
        cellItems[slot] = i;
        gridPosX[slot] = posX[i];
        gridPosY[slot] = posY[i];
        gridSize[slot] = sizeAvg[i];
        gridRing[slot] = cellRing[i];
        gridCell[slot] = cell;
      }

      // Repulsion over the neighboring cells
      for (var a = 0; a < n; a++) {
        if (a % _cancellationCheckInterval == 0) check();
        final ax = gridPosX[a];
        final ay = gridPosY[a];
        final aSize = gridSize[a];
        var fx = 0.0;
        var fy = 0.0;
        final cell = gridCell[a];
        final cellX = cell % cols;
        final cellY = cell ~/ cols;
        final ring = gridRing[a];
        final minCellX = math.max(0, cellX - ring);
        final maxCellX = math.min(cols - 1, cellX + ring);
        final minCellY = math.max(0, cellY - ring);
        final maxCellY = math.min(rows - 1, cellY + ring);

        for (var ny = minCellY; ny <= maxCellY; ny++) {
          final rowBase = ny * cols;
          final slotEnd = cellStart[rowBase + maxCellX + 1];
          for (var b = cellStart[rowBase + minCellX]; b < slotEnd; b++) {
            if (a == b) continue;
            final pairMinDistance = (aSize + gridSize[b]) * _minDistanceFactor;
            final dx = ax - gridPosX[b];
            final dy = ay - gridPosY[b];
            final distSq = dx * dx + dy * dy;
            final cutoff = pairMinDistance * _maxRepulsionDistanceFactor;
            if (distSq > cutoff * cutoff || distSq <= 1) continue;
            final distance = math.sqrt(distSq);
            final effective = math.max(distance, pairMinDistance);
            final force = repulsion / (effective * effective) + (distance < pairMinDistance ? extraRepulsion : 0);
            fx += dx / distance * force;
            fy += dy / distance * force;
          }
        }
        gridForceX[a] = fx;
        gridForceY[a] = fy;
      }
      for (var slot = 0; slot < n; slot++) {
        final i = cellItems[slot];
        forceX[i] = gridForceX[slot];
        forceY[i] = gridForceY[slot];
      }

      // Springs
      for (final (from, to) in springPairs) {
        final dx = posX[to] - posX[from];
        final dy = posY[to] - posY[from];
        final distSq = dx * dx + dy * dy;
        if (distSq <= 1) continue;
        final distance = math.sqrt(distSq);
        final force = distance * config.attractionStrength;
        final fx = dx / distance * force;
        final fy = dy / distance * force;
        forceX[from] += fx;
        forceY[from] += fy;
        forceX[to] -= fx;
        forceY[to] -= fy;
      }

      // Integrate with cooling and damping, inside the bounds
      final maxVelocity = _maxVelocity * (1 - coolingStep * iteration);
      final maxVelocitySq = maxVelocity * maxVelocity;
      for (var i = 0; i < n; i++) {
        var vx = velX[i] + forceX[i] + (centerX - posX[i]) * _centeringStrength;
        var vy = velY[i] + forceY[i] + (centerY - posY[i]) * _centeringStrength;
        final speedSq = vx * vx + vy * vy;
        if (speedSq > maxVelocitySq) {
          final s = maxVelocity / math.sqrt(speedSq);
          vx *= s;
          vy *= s;
        }
        vx *= config.damping;
        vy *= config.damping;
        velX[i] = vx;
        velY[i] = vy;
        posX[i] = (posX[i] + vx).clamp(margin, math.max(margin, maxX));
        posY[i] = (posY[i] + vy).clamp(margin, math.max(margin, maxY));
      }
    }

    return Graph.withClassifiedEdges([
      for (var i = 0; i < n; i++) graph.nodes[ids[i]]!.copyWith(position: Offset(posX[i], posY[i])),
    ], graph.edges);
  }
}
