import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_edge_style.dart';
import 'package:interactive_graphs_example/models/layout_algorithm.dart';
import 'package:interactive_graphs_example/models/node_data.dart';

/// Texts of the playground screen.
abstract final class PlaygroundCopy {
  /// Screen title.
  static const String title = 'Playground';

  /// Ports filter chip.
  static const String ports = 'Ports';

  /// Debug bounds filter chip.
  static const String debugBounds = 'Debug bounds';

  /// Reset positions chip.
  static const String resetPositions = 'Reset positions';

  /// Center graph button.
  static const String centerGraph = 'Center graph';

  /// Add node button.
  static const String addNode = 'Add node';

  /// Add edge button.
  static const String addEdge = 'Add edge';

  /// Start auto generation.
  static const String generateNodes = 'Generate nodes';

  /// Stop auto generation.
  static const String stopGenerating = 'Stop generating';

  /// Clear graph button.
  static const String clearGraph = 'Clear graph';

  /// Zoom out button.
  static const String zoomOut = 'Zoom out';

  /// Zoom in button.
  static const String zoomIn = 'Zoom in';

  /// Node label field.
  static const String nodeLabel = 'Node label';

  /// The color swatch that picks a random color.
  static const String randomColor = 'Random color';

  /// Create node button.
  static const String createNode = 'Create node';

  /// Edge form without nodes.
  static const String createNodesFirst = 'Create nodes first!';

  /// Edge start field.
  static const String from = 'From';

  /// Edge end field.
  static const String to = 'To';

  /// Arrow between the edge fields.
  static const String arrow = '→';

  /// Create edge button.
  static const String createEdge = 'Create edge';

  /// Edge label field.
  static const String edgeLabel = 'Label (optional)';

  /// Cancel connect mode.
  static const String cancel = 'Cancel';

  /// Edge form with unknown node labels.
  static const String unknownNodes = 'Type the labels of two existing nodes';

  /// Subtitle with the graph size.
  static String graphSize(int nodes, int edges) => '$nodes nodes · $edges edges';

  /// Current zoom level.
  static String zoomPercent(double scale) => '${(scale * 100).toInt()}%';

  /// Default label of a new node.
  static String defaultNodeLabel(String id) => 'Node $id';

  /// Connect mode banner.
  static String connectFrom(String label) => 'Click another node to connect from "$label"';

  /// Node form with a label that is taken.
  static String duplicateNode(String label) => 'A node named "$label" already exists';

  /// Label position slider caption.
  static String labelPosition(double offset) {
    final where = switch (offset) {
      < 0.3 => 'Start',
      > 0.7 => 'End',
      _ => 'Center',
    };
    return 'Label Position: $where';
  }

  /// Layout algorithm toggle.
  static String layoutAlgorithm(LayoutAlgorithm algorithm) => switch (algorithm) {
    LayoutAlgorithm.hierarchical => 'Hierarchical',
    LayoutAlgorithm.forceDirected => 'Force',
  };

  /// Layout direction toggle.
  static String layoutDirection(LayoutDirection direction) => switch (direction) {
    LayoutDirection.horizontal => 'Horizontal',
    LayoutDirection.vertical => 'Vertical',
  };

  /// Edge style toggle.
  static String edgeStyle(PlaygroundEdgeStyle style) => switch (style) {
    PlaygroundEdgeStyle.regular => 'Regular',
    PlaygroundEdgeStyle.sCurve => 'S-curve',
    PlaygroundEdgeStyle.rightAngle => 'Right angle',
  };

  /// Name of a node color swatch.
  static String nodeColor(NodeColorType color) => switch (color) {
    NodeColorType.pink => 'Pink',
    NodeColorType.orange => 'Orange',
    NodeColorType.yellow => 'Yellow',
    NodeColorType.green => 'Green',
    NodeColorType.blue => 'Blue',
  };
}
