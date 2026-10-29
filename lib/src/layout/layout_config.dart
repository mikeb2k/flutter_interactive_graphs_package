import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:interactive_graphs/src/model/graph.dart';
import 'package:interactive_graphs/src/model/graph_node.dart';

/// A user-supplied layout algorithm: returns [graph] with new node positions (centers, in logical
/// pixels). Finish with [Graph.withClassifiedEdges] so edges get their [EdgeType].
typedef LayoutProvider = Graph Function(Graph graph, LayoutConfig config);

/// Flow direction of a [HierarchicalLayoutConfig].
enum LayoutDirection {
  /// Levels run left to right.
  horizontal,

  /// Levels run top to bottom.
  vertical,
}

/// Configuration of a graph layout algorithm.
///
/// Every length is in logical pixels. [canvasSize] is filled in by the viewer from the size it is
/// laid out at; it is [Size.zero] until then.
///
/// See [HierarchicalLayoutConfig], [ForceDirectedLayoutConfig] and [CustomLayoutConfig].
@immutable
sealed class LayoutConfig {
  const LayoutConfig({this.canvasSize = Size.zero});

  /// Hierarchical (layered) layout, best for DAGs and trees. See [HierarchicalLayoutConfig].
  const factory LayoutConfig.hierarchical({
    LayoutDirection direction,
    double levelSpacing,
    double nodeSpacing,
    Size canvasSize,
  }) = HierarchicalLayoutConfig;

  /// Force-directed (spring embedder) layout, best for general graphs. See
  /// [ForceDirectedLayoutConfig].
  const factory LayoutConfig.forceDirected({
    int iterations,
    double repulsionStrength,
    double attractionStrength,
    double damping,
    Size canvasSize,
  }) = ForceDirectedLayoutConfig;

  /// A layout computed by [provider]. See [CustomLayoutConfig].
  const factory LayoutConfig.custom(LayoutProvider provider, {Size canvasSize}) = CustomLayoutConfig._positional;

  /// Size of a node without explicit or measured size, in logical pixels.
  static const double defaultNodeSize = GraphNode.defaultSize;

  /// Size of the canvas the viewer lays the graph out for.
  final Size canvasSize;

  /// Fallback node size used for nodes that have no size yet.
  double get nodeSize => defaultNodeSize;

  /// Returns a copy with [canvasSize] replaced.
  LayoutConfig withCanvas(Size canvasSize);
}

/// Sugiyama-style layered layout: removes cycles, assigns levels by longest path, reduces edge
/// crossings with the barycenter heuristic, then places levels [levelSpacing] apart and nodes of a
/// level [nodeSpacing] apart. Both spacings grow to fit the largest node.
final class HierarchicalLayoutConfig extends LayoutConfig {
  /// Creates a hierarchical layout configuration.
  const HierarchicalLayoutConfig({
    this.direction = LayoutDirection.horizontal,
    this.levelSpacing = 150,
    this.nodeSpacing = 100,
    super.canvasSize,
  });

  /// Direction the levels flow in.
  final LayoutDirection direction;

  /// Distance between consecutive levels, at least the largest node plus a 60 px clearance.
  final double levelSpacing;

  /// Distance between nodes of one level, at least the largest node plus a 40 px clearance.
  final double nodeSpacing;

  @override
  HierarchicalLayoutConfig withCanvas(Size canvasSize) => HierarchicalLayoutConfig(
    direction: direction,
    levelSpacing: levelSpacing,
    nodeSpacing: nodeSpacing,
    canvasSize: canvasSize,
  );

  @override
  bool operator ==(Object other) =>
      other is HierarchicalLayoutConfig &&
      other.direction == direction &&
      other.levelSpacing == levelSpacing &&
      other.nodeSpacing == nodeSpacing &&
      other.canvasSize == canvasSize;

  @override
  int get hashCode => Object.hash(direction, levelSpacing, nodeSpacing, canvasSize);
}

/// Fruchterman–Reingold style simulation: nodes repel each other, edges pull their ends together
/// and a weak force keeps the graph centered. The canvas sets the aspect ratio and the minimum
/// bounds; graphs with more nodes than the canvas has room for spread over larger bounds.
final class ForceDirectedLayoutConfig extends LayoutConfig {
  /// Creates a force-directed layout configuration.
  const ForceDirectedLayoutConfig({
    this.iterations = 200,
    this.repulsionStrength = 500,
    this.attractionStrength = 0.02,
    this.damping = 0.85,
    super.canvasSize,
  });

  /// Number of simulation steps; also sets the cooling schedule.
  final int iterations;

  /// How strongly nodes push each other apart.
  final double repulsionStrength;

  /// How strongly connected nodes pull together.
  final double attractionStrength;

  /// Velocity damping in `0..1`: higher is calmer but converges slower.
  final double damping;

  @override
  ForceDirectedLayoutConfig withCanvas(Size canvasSize) => ForceDirectedLayoutConfig(
    iterations: iterations,
    repulsionStrength: repulsionStrength,
    attractionStrength: attractionStrength,
    damping: damping,
    canvasSize: canvasSize,
  );

  @override
  bool operator ==(Object other) =>
      other is ForceDirectedLayoutConfig &&
      other.iterations == iterations &&
      other.repulsionStrength == repulsionStrength &&
      other.attractionStrength == attractionStrength &&
      other.damping == damping &&
      other.canvasSize == canvasSize;

  @override
  int get hashCode => Object.hash(iterations, repulsionStrength, attractionStrength, damping, canvasSize);
}

/// A layout computed by a [LayoutProvider].
///
/// Custom layouts run on the UI isolate, so the provider may capture anything. Keep it fast, or
/// compute positions yourself and hand them over with `GraphViewerController.moveNode`.
final class CustomLayoutConfig extends LayoutConfig {
  /// Creates a custom layout configuration.
  const CustomLayoutConfig({required this.provider, super.canvasSize});

  const CustomLayoutConfig._positional(this.provider, {super.canvasSize});

  /// The layout algorithm.
  final LayoutProvider provider;

  @override
  CustomLayoutConfig withCanvas(Size canvasSize) => CustomLayoutConfig(provider: provider, canvasSize: canvasSize);

  @override
  bool operator ==(Object other) =>
      other is CustomLayoutConfig && other.provider == provider && other.canvasSize == canvasSize;

  @override
  int get hashCode => Object.hash(provider, canvasSize);
}
