import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/port_side.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_defaults.dart';
import 'package:interactive_graphs_example/models/node_data.dart';
import 'package:interactive_graphs_example/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A playground node: a colored rounded box with its label and a port (anchor) for every edge end,
/// spread evenly along the sides.
class PlaygroundNode extends StatelessWidget {
  /// Creates a node.
  const PlaygroundNode({
    super.key,
    required this.data,
    required this.ports,
    required this.isSelected,
    required this.isHighlighted,
  });

  /// Label and color.
  final NodeData data;

  /// Anchor ids by side.
  final Map<PortSide, List<String>> ports;

  /// Whether the node is selected: full border.
  final bool isSelected;

  /// Whether the node is hovered or dragged: faint border.
  final bool isHighlighted;

  /// Size of a port dot.
  static const double portSize = 8;

  /// How far a port sticks out of the node.
  static const double portOutset = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = NodePalette.of(context);
    final fill = data.colorType.fill(palette);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: PlaygroundDefaults.panelDurationOf(context),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor(scheme), width: 2),
            boxShadow: [
              BoxShadow(color: scheme.shadow.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Text(
            data.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: data.colorType.onFill(palette)),
          ),
        ),
        for (final MapEntry(key: side, value: anchorIds) in ports.entries)
          for (final (index, anchorId) in anchorIds.indexed)
            Positioned.fill(
              child: Align(
                alignment: _alignment(side, index, anchorIds.length),
                child: Transform.translate(
                  offset: _outward(side),
                  child: GraphAnchor(
                    id: anchorId,
                    child: Container(
                      width: portSize,
                      height: portSize,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: fill, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Color _borderColor(ColorScheme scheme) {
    if (isSelected) return scheme.onSurface;
    if (isHighlighted) return scheme.onSurface.withValues(alpha: 0.4);
    return scheme.onSurface.withValues(alpha: 0);
  }

  /// Spreads the anchors of a side evenly along it.
  Alignment _alignment(PortSide side, int index, int count) {
    final bias = (index + 1) / (count + 1) * 2 - 1;
    return switch (side) {
      PortSide.left => Alignment(-1, bias),
      PortSide.right => Alignment(1, bias),
      PortSide.top => Alignment(bias, -1),
      PortSide.bottom => Alignment(bias, 1),
    };
  }

  Offset _outward(PortSide side) => switch (side) {
    PortSide.left => const Offset(-portOutset, 0),
    PortSide.right => const Offset(portOutset, 0),
    PortSide.top => const Offset(0, -portOutset),
    PortSide.bottom => const Offset(0, portOutset),
  };
}
