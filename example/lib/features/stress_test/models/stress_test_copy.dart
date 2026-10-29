import 'package:interactive_graphs_example/features/stress_test/models/stress_node_size.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_preset.dart';
import 'package:interactive_graphs_example/models/layout_algorithm.dart';

/// Texts of the stress test screen.
abstract final class StressTestCopy {
  /// Screen title.
  static const String title = 'Stress Test';

  /// Back button.
  static const String back = 'Back';

  /// Regenerate button.
  static const String regenerate = 'Regenerate graph';

  /// Debug bounds button.
  static const String toggleDebugBounds = 'Toggle debug bounds';

  /// Label of the node count picker.
  static const String nodes = 'Nodes:';

  /// Label of the layout picker.
  static const String layout = 'Layout:';

  /// Batched edge rendering toggle.
  static const String batchedEdges = 'Batched edges';

  /// Shown until the first layout is fitted.
  static const String calculatingLayout = 'Calculating layout…';

  /// Shown while a later layout pass runs.
  static const String layingOut = 'Laying out…';

  /// Button that expands the zoom toolbar.
  static const String zoomControls = 'Zoom controls';

  /// Center button.
  static const String centerGraph = 'Center graph';

  /// Zoom out button.
  static const String zoomOut = 'Zoom out';

  /// Zoom in button.
  static const String zoomIn = 'Zoom in';

  /// Node and edge count.
  static String stats(int nodeCount, int edgeCount) => '$nodeCount nodes · $edgeCount edges';

  /// Zoom level as a percentage.
  static String zoomPercent(double scale) => '${(scale * 100).toInt()}%';

  /// Name of a node count preset.
  static String preset(StressPreset preset) => '${preset.nodeCount}';

  /// Name of a layout algorithm.
  static String layoutAlgorithm(LayoutAlgorithm algorithm) => switch (algorithm) {
    LayoutAlgorithm.hierarchical => 'Hierarchical',
    LayoutAlgorithm.forceDirected => 'Force',
  };

  /// Text of generated node [index] of [size].
  static String nodeLabel(int index, StressNodeSize size) => switch (size) {
    StressNodeSize.small => '$index',
    StressNodeSize.medium => 'Node $index',
    StressNodeSize.large => 'Node $index\nTask $index',
  };
}
