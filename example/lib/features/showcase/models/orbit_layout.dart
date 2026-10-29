import 'dart:math' as math;

import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:material_ui/material_ui.dart';

/// Circular layout: every node on one ring, in breadth-first order from the roots so that
/// neighbours sit next to each other. A custom `LayoutProvider`.
abstract final class OrbitLayout {
  /// Smallest ring radius.
  static const double minRadius = 260;

  /// Room one node takes up along the ring.
  static const double nodeArc = 290;

  /// Vertical squash of the ring.
  static const double squash = 0.8;

  /// Lays [graph] out on a ring around the center of [config]'s canvas.
  static Graph run(Graph graph, LayoutConfig config) {
    final ids = graph.nodes.keys.toList();
    var roots = [
      for (final id in ids)
        if (!graph.edges.any((edge) => edge.toId == id && edge.fromId != id)) id,
    ];
    if (roots.isEmpty) roots = ids.take(1).toList();

    final order = [...roots];
    for (var index = 0; index < order.length; index++) {
      final id = order[index];
      for (final edge in graph.edges) {
        if (edge.fromId == id && !order.contains(edge.toId)) order.add(edge.toId);
      }
    }
    order.addAll(ids.where((id) => !order.contains(id)));

    final radius = math.max(minRadius, nodeArc * order.length / (2 * math.pi));
    final center = config.canvasSize.center(Offset.zero);
    final positioned = [
      for (final (position, id) in order.indexed)
        graph.nodes[id]!.copyWith(position: _pointOnRing(center, radius, position, order.length)),
    ];
    return Graph.withClassifiedEdges(positioned, graph.edges);
  }

  static Offset _pointOnRing(Offset center, double radius, int position, int count) {
    final angle = 2 * math.pi * position / count - math.pi;
    return Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle) * squash);
  }
}
