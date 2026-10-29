import 'package:interactive_graphs_example/features/stress_test/models/stress_node_size.dart';
import 'package:interactive_graphs_example/models/node_data.dart';
import 'package:material_ui/material_ui.dart';

/// Application data of a generated node, looked up by node id.
@immutable
class StressNodeData {
  /// Creates node data.
  const StressNodeData({required this.label, required this.colorType, required this.size});

  /// Text shown on the node.
  final String label;

  /// Accent color.
  final NodeColorType colorType;

  /// Size class.
  final StressNodeSize size;

  /// Returns a copy with the given fields replaced.
  StressNodeData copyWith({String? label, NodeColorType? colorType, StressNodeSize? size}) => StressNodeData(
    label: label ?? this.label,
    colorType: colorType ?? this.colorType,
    size: size ?? this.size,
  );

  @override
  bool operator ==(Object other) =>
      other is StressNodeData && other.label == label && other.colorType == colorType && other.size == size;

  @override
  int get hashCode => Object.hash(label, colorType, size);
}
