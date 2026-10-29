import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

void main() {
  Graph randomGraph(int nodeCount, {int seed = 42}) {
    final random = math.Random(seed);
    final nodes = [
      for (var i = 0; i < nodeCount; i++)
        GraphNode('n$i', size: Size(20 + random.nextInt(200).toDouble(), 20 + random.nextInt(150).toDouble())),
    ];
    final edges = [
      for (var i = 0; i < nodeCount * 2; i++)
        GraphEdge('n${random.nextInt(nodeCount)}', 'n${random.nextInt(nodeCount)}'),
    ].where((e) => !e.isSelfLoop);
    return Graph.withClassifiedEdges(nodes, edges);
  }

  /// Plain O(n²) version of the simulation, the reference the spatial grid must match.
  Map<String, Offset> bruteForce(Graph graph, ForceDirectedLayoutConfig config) {
    final ids = graph.nodes.keys.toList();
    final n = ids.length;
    final sizes = [for (final id in ids) ForceDirectedLayout.averageSize(graph.nodes[id]!, GraphNode.defaultSize)];
    final avgSize = sizes.reduce((a, b) => a + b) / n;
    final scale = ForceDirectedLayout.boundsScale(n, avgSize, config.canvasSize.width, config.canvasSize.height);
    final width = config.canvasSize.width * scale;
    final height = config.canvasSize.height * scale;
    final index = {for (var i = 0; i < n; i++) ids[i]: i};
    final springs = <(int, int)>{for (final e in graph.edges) (index[e.fromId]!, index[e.toId]!)}.toList();
    final cx = width / 2;
    final cy = height / 2;
    final radius = math.min(width, height) * 0.3;
    final px = [for (var i = 0; i < n; i++) cx + radius * math.cos(i * 2 * math.pi / n)];
    final py = [for (var i = 0; i < n; i++) cy + radius * math.sin(i * 2 * math.pi / n)];
    final vx = List.filled(n, 0.0);
    final vy = List.filled(n, 0.0);
    final margin = avgSize;
    final coolingStep = config.iterations > 1 ? 0.9 / (config.iterations - 1) : 0.0;

    for (var iteration = 0; iteration < config.iterations; iteration++) {
      final fx = List.filled(n, 0.0);
      final fy = List.filled(n, 0.0);
      for (var a = 0; a < n; a++) {
        for (var b = 0; b < n; b++) {
          if (a == b) continue;
          final minDistance = (sizes[a] + sizes[b]) * 0.9;
          final dx = px[a] - px[b];
          final dy = py[a] - py[b];
          final distSq = dx * dx + dy * dy;
          final cutoff = minDistance * 3;
          if (distSq > cutoff * cutoff || distSq <= 1) continue;
          final distance = math.sqrt(distSq);
          final effective = math.max(distance, minDistance);
          final force =
              config.repulsionStrength / (effective * effective) +
              (distance < minDistance ? config.repulsionStrength * 0.5 : 0);
          fx[a] += dx / distance * force;
          fy[a] += dy / distance * force;
        }
      }
      for (final (f, t) in springs) {
        final dx = px[t] - px[f];
        final dy = py[t] - py[f];
        final distSq = dx * dx + dy * dy;
        if (distSq <= 1) continue;
        final distance = math.sqrt(distSq);
        final force = distance * config.attractionStrength;
        fx[f] += dx / distance * force;
        fy[f] += dy / distance * force;
        fx[t] -= dx / distance * force;
        fy[t] -= dy / distance * force;
      }
      final maxVelocity = 10 * (1 - coolingStep * iteration);
      for (var i = 0; i < n; i++) {
        var nvx = vx[i] + fx[i] + (cx - px[i]) * 0.01;
        var nvy = vy[i] + fy[i] + (cy - py[i]) * 0.01;
        final speed = math.sqrt(nvx * nvx + nvy * nvy);
        if (speed > maxVelocity) {
          nvx *= maxVelocity / speed;
          nvy *= maxVelocity / speed;
        }
        vx[i] = nvx * config.damping;
        vy[i] = nvy * config.damping;
        px[i] = (px[i] + vx[i]).clamp(margin, width - margin);
        py[i] = (py[i] + vy[i]).clamp(margin, height - margin);
      }
    }
    return {for (var i = 0; i < n; i++) ids[i]: Offset(px[i], py[i])};
  }

  test('places nodes within the canvas', () {
    final graph = Graph.build(
      (g) => g
        ..nodes(['A', 'B', 'C'])
        ..edges([('A', 'B'), ('B', 'C')]),
    );
    const config = ForceDirectedLayoutConfig(canvasSize: Size(600, 400), iterations: 100);

    for (final node in ForceDirectedLayout.run(graph, config).nodes.values) {
      expect(node.position.dx, inInclusiveRange(0, 600));
      expect(node.position.dy, inInclusiveRange(0, 400));
    }
  });

  test('a single node sits in the center', () {
    final result = ForceDirectedLayout.run(
      Graph.build((g) => g.nodes(['A'])),
      const ForceDirectedLayoutConfig(canvasSize: Size(600, 400)),
    );

    expect(result.nodes['A']!.position.dx, closeTo(300, 50));
    expect(result.nodes['A']!.position.dy, closeTo(200, 50));
  });

  test('cycles are laid out and every edge classified', () {
    final result = ForceDirectedLayout.run(
      Graph.build(
        (g) => g
          ..nodes(['A', 'B', 'C'])
          ..edges([('A', 'B'), ('B', 'C'), ('C', 'A')]),
      ),
      const ForceDirectedLayoutConfig(canvasSize: Size(600, 400)),
    );

    expect(result.nodes, hasLength(3));
    expect(result.edges.every((e) => e.type != null), isTrue);
  });

  test('an unmeasured canvas leaves the graph as it is', () {
    final graph = Graph.build((g) => g.nodes(['A', 'B']));

    expect(ForceDirectedLayout.run(graph, const ForceDirectedLayoutConfig()), same(graph));
  });

  test('a parallel edge keeps its id and moves no node', () {
    final single = Graph.build(
      (g) => g
        ..nodes(['A', 'B', 'C', 'D'])
        ..edges([('A', 'B'), ('A', 'C'), ('B', 'D'), ('A', 'D')]),
    );
    final doubled = single.rebuild((g) => g.edge('A', 'D', id: 'again'));
    const config = ForceDirectedLayoutConfig(canvasSize: Size(800, 600), iterations: 50);

    final result = ForceDirectedLayout.run(doubled, config);
    expect(result.nodes, ForceDirectedLayout.run(single, config).nodes);
    expect(result.edges.any((e) => e.id == 'again'), isTrue);
  });

  test('the spatial grid matches brute force while the simulation is deterministic', () {
    for (final iterations in [1, 3, 5]) {
      final graph = randomGraph(300);
      final config = ForceDirectedLayoutConfig(canvasSize: const Size(1600, 1200), iterations: iterations);

      final grid = ForceDirectedLayout.run(graph, config);
      final reference = bruteForce(graph, config);
      for (final MapEntry(key: id, value: node) in grid.nodes.entries) {
        expect((node.position - reference[id]!).distance, lessThan(1e-6), reason: '$id after $iterations');
      }
    }
  });

  test('a large graph spreads beyond the canvas but stays in the grown bounds', () {
    final graph = randomGraph(500);
    const config = ForceDirectedLayoutConfig(canvasSize: Size(2000, 1500));
    final avgSize = graph.nodes.values.map((n) => (n.size!.width + n.size!.height) / 2).reduce((a, b) => a + b) / 500;
    final scale = ForceDirectedLayout.boundsScale(500, avgSize, 2000, 1500);

    final result = ForceDirectedLayout.run(graph, config);
    expect(scale, greaterThan(1));
    for (final node in result.nodes.values) {
      expect(node.position.dx, inInclusiveRange(0, 2000 * scale));
      expect(node.position.dy, inInclusiveRange(0, 1500 * scale));
    }
  });

  test('cancellation aborts the simulation and is polled within one iteration', () {
    final graph = randomGraph(500);
    var checks = 0;

    expect(
      () => ForceDirectedLayout.run(
        graph,
        const ForceDirectedLayoutConfig(canvasSize: Size(1600, 1200)),
        checkCancelled: () {
          if (++checks > 3) throw const LayoutCancelledException();
        },
      ),
      throwsA(isA<LayoutCancelledException>()),
    );

    checks = 0;
    ForceDirectedLayout.run(
      graph,
      const ForceDirectedLayoutConfig(canvasSize: Size(1600, 1200), iterations: 1),
      checkCancelled: () => checks++,
    );
    expect(checks, greaterThan(1));
  });

  test('is deterministic', () {
    final graph = randomGraph(60);
    const config = ForceDirectedLayoutConfig(canvasSize: Size(800, 600));

    expect(ForceDirectedLayout.run(graph, config), ForceDirectedLayout.run(graph, config));
  });
}
