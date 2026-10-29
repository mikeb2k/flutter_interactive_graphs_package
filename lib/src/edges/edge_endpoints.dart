import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:interactive_graphs/src/edges/edge_geometry.dart';
import 'package:interactive_graphs/src/model/graph_edge.dart';
import 'package:interactive_graphs/src/model/graph_node.dart';

/// How far a parallel edge bends away from the straight line, and the angle it leaves its node at.
@immutable
final class EdgeBend {
  /// Creates a bend of [amount] (control point offset as a fraction of the edge length).
  const EdgeBend(this.amount);

  /// Control point offset as a fraction of the edge length; for self loops, extra loop height.
  final double amount;

  /// Angle between the curve's start tangent and the straight line.
  double get tangentAngle => EdgeGeometry.curveTangentAngle(amount);

  @override
  bool operator ==(Object other) => other is EdgeBend && other.amount == amount;

  @override
  int get hashCode => amount.hashCode;

  @override
  String toString() => 'EdgeBend($amount)';
}

/// Spreads edges that share their endpoints (and anchors) so they don't draw on top of each other.
abstract final class ParallelEdges {
  /// Bend of every edge that has a twin, by edge id. Edges without a twin are left out.
  static Map<String, EdgeBend> bends(Iterable<GraphEdge> edges, {double step = EdgeGeometry.parallelEdgeBend}) {
    final groups = <(String, String, String?, String?), List<GraphEdge>>{};
    for (final edge in edges) {
      groups.putIfAbsent((edge.fromId, edge.toId, edge.fromAnchor, edge.toAnchor), () => []).add(edge);
    }

    final bends = <String, EdgeBend>{};
    for (final group in groups.values) {
      if (group.length < 2) continue;
      final sorted = [...group]..sort((a, b) => a.id.compareTo(b.id));

      if (sorted.first.isSelfLoop) {
        for (var i = 0; i < sorted.length; i++) {
          bends[sorted[i].id] = EdgeBend(i * EdgeGeometry.selfLoopNestedGrowth);
        }
        continue;
      }

      // Back edges fan out on the side of their usual curve and never go straight
      final halfSpan = (sorted.length - 1) / 2 * step;
      final first = sorted.any((e) => e.type == EdgeType.back)
          ? math.max(EdgeGeometry.curveBend - halfSpan, step / 2)
          : -halfSpan;
      for (var i = 0; i < sorted.length; i++) {
        bends[sorted[i].id] = EdgeBend(first + i * step);
      }
    }
    return bends;
  }
}

/// Where an edge starts and ends on its nodes.
abstract final class EdgeEndpoints {
  /// Gap between a node's boundary and the edge end.
  static const double padding = 4;

  /// Start and end of [edge] between nodes centered at [fromCenter] and [toCenter].
  ///
  /// An anchor offset (relative to its node's top-left corner) pins that end; otherwise the end
  /// sits on the node's box (plus [padding]) in the direction of the other end, rotated by the
  /// curve's tangent angle for curved edges. Self loops start and end on the node's top side.
  /// Missing sizes fall back to [GraphNode.defaultSize].
  static (Offset, Offset) resolve({
    required GraphEdge edge,
    required Offset fromCenter,
    required Offset toCenter,
    Size? fromSize,
    Size? toSize,
    EdgeBend? bend,
    Offset? fromAnchorOffset,
    Offset? toAnchorOffset,
  }) {
    const fallback = Size.square(GraphNode.defaultSize);
    final startBox = fromSize ?? fallback;
    final endBox = toSize ?? fallback;
    final curveAngle = _curveAngle(edge, bend);

    final anchoredStart = fromAnchorOffset == null ? null : _topLeft(fromCenter, startBox) + fromAnchorOffset;
    final anchoredEnd = toAnchorOffset == null ? null : _topLeft(toCenter, endBox) + toAnchorOffset;

    return switch ((anchoredStart, anchoredEnd)) {
      (final Offset start, final Offset end) => (start, end),
      (final Offset start, null) => (start, _towards(start, toCenter, endBox, outbound: false, curveAngle: curveAngle)),
      (null, final Offset end) => (_towards(end, fromCenter, startBox, outbound: true, curveAngle: curveAngle), end),
      (null, null) when edge.isSelfLoop => _selfLoop(fromCenter, startBox, bend?.amount ?? 0),
      (null, null) => _boxToBox(fromCenter, startBox, toCenter, endBox, curveAngle),
    };
  }

  static double _curveAngle(GraphEdge edge, EdgeBend? bend) {
    if (edge.isSelfLoop) return 0;
    if (bend != null) return bend.tangentAngle;
    if (edge.type == EdgeType.back) return EdgeGeometry.curveTangentAngle(EdgeGeometry.curveBend);
    return 0;
  }

  static Offset _topLeft(Offset center, Size size) => center - Offset(size.width / 2, size.height / 2);

  /// Point on the box around [center] facing [fixed], for an edge that leaves the box ([outbound])
  /// or enters it.
  static Offset _towards(Offset fixed, Offset center, Size box, {required bool outbound, required double curveAngle}) {
    final direction = outbound ? fixed - center : center - fixed;
    final unit = EdgeGeometry.normalize(direction);
    if (unit == null) return center;
    final rotated = EdgeGeometry.rotate(unit, outbound ? curveAngle : -curveAngle);
    final reach = EdgeGeometry.boxRadius(rotated, box.width / 2, box.height / 2) + padding;
    return outbound ? center + rotated * reach : center - rotated * reach;
  }

  static (Offset, Offset) _boxToBox(Offset fromCenter, Size fromBox, Offset toCenter, Size toBox, double curveAngle) {
    final unit = EdgeGeometry.normalize(toCenter - fromCenter);
    if (unit == null) return (fromCenter, toCenter);
    final startDirection = EdgeGeometry.rotate(unit, curveAngle);
    final endDirection = EdgeGeometry.rotate(unit, -curveAngle);
    final startReach = EdgeGeometry.boxRadius(startDirection, fromBox.width / 2, fromBox.height / 2) + padding;
    final endReach = EdgeGeometry.boxRadius(endDirection, toBox.width / 2, toBox.height / 2) + padding;
    return (fromCenter + startDirection * startReach, toCenter - endDirection * endReach);
  }

  static (Offset, Offset) _selfLoop(Offset center, Size box, double bend) {
    final spread = math.min(
      EdgeGeometry.selfLoopSpread + bend * EdgeGeometry.selfLoopSpreadPerBend,
      EdgeGeometry.selfLoopMaxSpread,
    );
    final halfWidth = box.width / 2 * spread;
    final top = center.dy - box.height / 2;
    return (Offset(center.dx - halfWidth, top), Offset(center.dx + halfWidth, top));
  }
}
