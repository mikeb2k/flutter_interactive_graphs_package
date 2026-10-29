import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_copy.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_defaults.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_edge_style.dart';
import 'package:interactive_graphs_example/models/layout_algorithm.dart';
import 'package:interactive_graphs_example/widgets/connected_toggle_group.dart';
import 'package:material_ui/material_ui.dart';

/// The option row under the playground's app bar, scrolling sideways when it does not fit: layout
/// algorithm, direction (hierarchical only), edge style, ports, debug bounds and reset positions.
class PlaygroundControlsBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates the row.
  const PlaygroundControlsBar({
    super.key,
    required this.controller,
    required this.layoutAlgorithm,
    required this.layoutDirection,
    required this.edgeStyle,
    required this.showPorts,
    required this.showDebugBounds,
    required this.onLayoutAlgorithmChange,
    required this.onLayoutDirectionChange,
    required this.onEdgeStyleChange,
    required this.onTogglePorts,
    required this.onToggleDebugBounds,
  });

  /// The viewer, for its manual positions.
  final GraphViewerController controller;

  /// Picked algorithm.
  final LayoutAlgorithm layoutAlgorithm;

  /// Picked direction.
  final LayoutDirection layoutDirection;

  /// Picked edge style.
  final PlaygroundEdgeStyle edgeStyle;

  /// Whether ports are on.
  final bool showPorts;

  /// Whether debug bounds are on.
  final bool showDebugBounds;

  /// Algorithm picks.
  final ValueChanged<LayoutAlgorithm> onLayoutAlgorithmChange;

  /// Direction picks.
  final ValueChanged<LayoutDirection> onLayoutDirectionChange;

  /// Edge style picks.
  final ValueChanged<PlaygroundEdgeStyle> onEdgeStyleChange;

  /// Toggles ports.
  final VoidCallback onTogglePorts;

  /// Toggles debug bounds.
  final VoidCallback onToggleDebugBounds;

  /// Height of the row.
  static const double height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          spacing: 12,
          children: [
            ConnectedToggleGroup<LayoutAlgorithm>(
              options: LayoutAlgorithm.values,
              selected: layoutAlgorithm,
              label: PlaygroundCopy.layoutAlgorithm,
              onSelect: onLayoutAlgorithmChange,
            ),
            AnimatedSize(
              duration: PlaygroundDefaults.panelDurationOf(context),
              alignment: Alignment.centerLeft,
              child: _directionGroup(),
            ),
            ConnectedToggleGroup<PlaygroundEdgeStyle>(
              options: PlaygroundEdgeStyle.values,
              selected: edgeStyle,
              label: PlaygroundCopy.edgeStyle,
              onSelect: onEdgeStyleChange,
            ),
            FilterChip(
              selected: showPorts,
              onSelected: _togglePorts,
              label: const Text(PlaygroundCopy.ports),
            ),
            FilterChip(
              selected: showDebugBounds,
              onSelected: _toggleDebugBounds,
              label: const Text(PlaygroundCopy.debugBounds),
            ),
            ListenableBuilder(listenable: controller, builder: _resetChip),
          ],
        ),
      ),
    );
  }

  Widget _directionGroup() {
    if (layoutAlgorithm != LayoutAlgorithm.hierarchical) return const SizedBox.shrink();
    return ConnectedToggleGroup<LayoutDirection>(
      options: LayoutDirection.values,
      selected: layoutDirection,
      label: PlaygroundCopy.layoutDirection,
      icon: _directionIcon,
      onSelect: onLayoutDirectionChange,
    );
  }

  IconData _directionIcon(LayoutDirection direction) => switch (direction) {
    LayoutDirection.horizontal => Icons.arrow_forward,
    LayoutDirection.vertical => Icons.arrow_downward,
  };

  Widget _resetChip(BuildContext context, Widget? child) => FilterChip(
    selected: false,
    onSelected: _resetHandler(),
    label: const Text(PlaygroundCopy.resetPositions),
  );

  ValueChanged<bool>? _resetHandler() {
    if (controller.manualPositions.isEmpty) return null;
    return _resetPositions;
  }

  void _resetPositions(bool _) => controller.clearManualPositions();

  void _togglePorts(bool _) => onTogglePorts();

  void _toggleDebugBounds(bool _) => onToggleDebugBounds();
}
