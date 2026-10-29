import 'package:interactive_graphs_example/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Accent color of a demo node.
enum NodeColorType {
  /// Pink.
  pink,

  /// Orange.
  orange,

  /// Yellow.
  yellow,

  /// Green.
  green,

  /// Blue.
  blue;

  /// Fill color in [palette].
  Color fill(NodePalette palette) => switch (this) {
    NodeColorType.pink => palette.pink,
    NodeColorType.orange => palette.orange,
    NodeColorType.yellow => palette.yellow,
    NodeColorType.green => palette.green,
    NodeColorType.blue => palette.blue,
  };

  /// Text color on [fill] in [palette].
  Color onFill(NodePalette palette) => switch (this) {
    NodeColorType.pink => palette.onPink,
    NodeColorType.orange => palette.onOrange,
    NodeColorType.yellow => palette.onYellow,
    NodeColorType.green => palette.onGreen,
    NodeColorType.blue => palette.onBlue,
  };
}

/// Application data of a demo node, looked up by node id.
@immutable
class NodeData {
  /// Creates node data.
  const NodeData({required this.label, required this.colorType});

  /// Text shown on the node.
  final String label;

  /// Accent color.
  final NodeColorType colorType;

  /// Returns a copy with the given fields replaced.
  NodeData copyWith({String? label, NodeColorType? colorType}) =>
      NodeData(label: label ?? this.label, colorType: colorType ?? this.colorType);

  @override
  bool operator ==(Object other) => other is NodeData && other.label == label && other.colorType == colorType;

  @override
  int get hashCode => Object.hash(label, colorType);
}
