import 'dart:math' as math;

import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_metrics.dart';
import 'package:material_ui/material_ui.dart';

/// Camera moves of the showcase that keep the graph between the overlays at the top ([top]) and
/// at the bottom ([bottom]) of the viewer.
extension ShowcaseCamera on GraphViewerController {
  /// Fits the whole graph between the overlays, animated.
  void fitBetween(double top, double bottom) {
    final bounds = GraphBounds.ofNodes(layoutedGraph.nodes.values);
    if (bounds.width <= 0 || bounds.height <= 0 || canvasSize.width <= 0) return;
    final scale = math
        .min(canvasSize.width * 0.9 / bounds.width, (canvasSize.height - top - bottom) * 0.88 / bounds.height)
        .clamp(0.2, 1.6);
    moveCamera(bounds.center, scale, top, bottom);
  }

  /// Moves the camera to [nodeId], zoomed in enough to read an expanded step.
  void focusOn(String nodeId, double top, double bottom) {
    final node = layoutedGraph.nodes[nodeId];
    if (node == null) return;
    moveCamera(node.position, focusScale, top, bottom);
  }

  /// Zoom that fits an expanded step comfortably.
  double get focusScale => math.max(math.min(1.1, canvasSize.width * 0.45 / ShowcaseMetrics.expandedStepWidth), 0.4);

  /// Centers the graph point [point] at [scale] between the overlays.
  void moveCamera(Offset point, double scale, double top, double bottom, {bool animated = true}) {
    // Node positions are drawn relative to the center of the position bounds
    final origin = graphCenter;
    updateTransform(
      scale: scale,
      offset: Offset(-(point.dx - origin.dx) * scale, (top - bottom) / 2 - (point.dy - origin.dy) * scale),
      animated: animated,
    );
  }
}
