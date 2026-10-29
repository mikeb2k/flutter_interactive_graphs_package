import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/showcase/models/orbit_layout.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_copy.dart';
import 'package:material_ui/material_ui.dart';

/// Layouts the showcase switches between.
enum ShowcaseLayout {
  /// Layered, left to right.
  flow(
    ShowcaseCopy.layoutFlow,
    Icons.account_tree,
    LayoutConfig.hierarchical(direction: LayoutDirection.horizontal, levelSpacing: 270, nodeSpacing: 120),
  ),

  /// Layered, top to bottom.
  stack(
    ShowcaseCopy.layoutStack,
    Icons.schema,
    LayoutConfig.hierarchical(direction: LayoutDirection.vertical, levelSpacing: 140, nodeSpacing: 240),
  ),

  /// Force-directed.
  organic(
    ShowcaseCopy.layoutOrganic,
    Icons.bubble_chart,
    LayoutConfig.forceDirected(iterations: 300, repulsionStrength: 900),
  ),

  /// Custom ring layout.
  orbit(ShowcaseCopy.layoutOrbit, Icons.donut_large, LayoutConfig.custom(OrbitLayout.run));

  const ShowcaseLayout(this.label, this.icon, this.config);

  /// Name in the layout picker.
  final String label;

  /// Icon in the layout picker.
  final IconData icon;

  /// Layout algorithm and settings.
  final LayoutConfig config;

  /// The layout that suits a window of [size]: left to right flow leaves a portrait screen mostly
  /// empty.
  static ShowcaseLayout homeFor(Size size) {
    if (size.width < size.height) return ShowcaseLayout.stack;
    return ShowcaseLayout.flow;
  }

  /// The other layered layout, so that the tour shows a layout change from the home layout.
  ShowcaseLayout get otherHierarchical {
    if (this == ShowcaseLayout.flow) return ShowcaseLayout.stack;
    return ShowcaseLayout.flow;
  }
}

/// Edge shapes the showcase switches between.
enum ShowcaseEdgeStyle {
  /// S-curves along the flow.
  curves(ShowcaseCopy.edgeCurves, Icons.gesture),

  /// Right angles.
  circuit(ShowcaseCopy.edgeCircuit, Icons.polyline),

  /// Straight lines.
  straight(ShowcaseCopy.edgeStraight, Icons.show_chart);

  const ShowcaseEdgeStyle(this.label, this.icon);

  /// Name in the edge style picker.
  final String label;

  /// Icon in the edge style picker.
  final IconData icon;
}
