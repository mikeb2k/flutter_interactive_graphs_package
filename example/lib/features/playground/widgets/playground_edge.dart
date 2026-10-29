import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/edge_data.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_edge_style.dart';
import 'package:material_ui/material_ui.dart';

/// A playground edge in the picked style, thicker when hovered or selected, with its optional label.
/// Back edges and self-loops always use the regular edge.
class PlaygroundEdge extends StatelessWidget {
  /// Creates an edge.
  const PlaygroundEdge({super.key, required this.details, required this.style, this.data});

  /// The edge and its ends.
  final EdgeDetails details;

  /// Picked edge style.
  final PlaygroundEdgeStyle style;

  /// Label of the edge, if any.
  final EdgeData? data;

  @override
  Widget build(BuildContext context) {
    return StyledEdge(
      details: details,
      strokeWidth: _strokeWidth(),
      shape: _shape(),
      label: _label(),
      labelOffset: data?.labelOffset,
      labelStyle: EdgeLabelStyle(fontSize: 11, rotateWithEdge: _shape() == EdgeShape.orthogonal),
    );
  }

  bool get _isLoop => details.edge.type == EdgeType.back || details.edge.type == EdgeType.selfLoop;

  EdgeShape _shape() => switch (style) {
    PlaygroundEdgeStyle.sCurve when !_isLoop => EdgeShape.orthogonal,
    PlaygroundEdgeStyle.rightAngle when !_isLoop => EdgeShape.rightAngle,
    _ => EdgeShape.auto,
  };

  double _strokeWidth() {
    if (details.isSelected) return 5;
    if (details.isHovered) return 3.5;
    return 2.5;
  }

  String? _label() {
    final label = data?.label;
    if (label == null || label.trim().isEmpty) return null;
    return label;
  }
}
