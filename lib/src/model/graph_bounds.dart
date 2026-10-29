import 'dart:math' as math;
import 'dart:ui';

import 'package:interactive_graphs/src/model/graph_node.dart';

/// Bounding boxes of node sets, in graph space.
abstract final class GraphBounds {
  /// Box around the node centers, or [Rect.zero] for no nodes.
  static Rect ofPositions(Iterable<GraphNode> nodes) => _bounds(nodes, includeSizes: false);

  /// Box around the node boxes (center ± half the size, [GraphNode.defaultSize] when unsized), or
  /// [Rect.zero] for no nodes.
  static Rect ofNodes(Iterable<GraphNode> nodes) => _bounds(nodes, includeSizes: true);

  static Rect _bounds(Iterable<GraphNode> nodes, {required bool includeSizes}) {
    if (nodes.isEmpty) return Rect.zero;
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;
    for (final node in nodes) {
      final size = includeSizes ? (node.size ?? const Size.square(GraphNode.defaultSize)) : Size.zero;
      left = math.min(left, node.position.dx - size.width / 2);
      right = math.max(right, node.position.dx + size.width / 2);
      top = math.min(top, node.position.dy - size.height / 2);
      bottom = math.max(bottom, node.position.dy + size.height / 2);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}
