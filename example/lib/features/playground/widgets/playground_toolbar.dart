import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_copy.dart';
import 'package:interactive_graphs_example/widgets/toolbar_button.dart';
import 'package:material_ui/material_ui.dart';

/// The floating toolbar of the playground: add node, add edge, generate, clear, and (when
/// [showZoomControls]) zoom out, the zoom level and zoom in, next to a center-graph button.
class PlaygroundToolbar extends StatelessWidget {
  /// Creates the toolbar.
  const PlaygroundToolbar({
    super.key,
    required this.controller,
    required this.isAutoGenerating,
    required this.showZoomControls,
    required this.onAddNode,
    required this.onAddEdge,
    required this.onToggleGenerating,
    required this.onClear,
  });

  /// The viewer, for the zoom level and the zoom and center actions.
  final GraphViewerController controller;

  /// Whether nodes are being generated.
  final bool isAutoGenerating;

  /// Whether the zoom buttons are part of the toolbar.
  final bool showZoomControls;

  /// Opens or closes the node form.
  final VoidCallback onAddNode;

  /// Opens or closes the edge form.
  final VoidCallback onAddEdge;

  /// Starts or stops generating.
  final VoidCallback onToggleGenerating;

  /// Clears the graph.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Material(
          color: scheme.surfaceContainer,
          elevation: 3,
          shape: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ToolbarButton(icon: Icons.add_circle, tooltip: PlaygroundCopy.addNode, onPressed: onAddNode),
                ToolbarButton(icon: Icons.add_link, tooltip: PlaygroundCopy.addEdge, onPressed: onAddEdge),
                ToolbarButton(icon: _generateIcon(), tooltip: _generateTooltip(), onPressed: onToggleGenerating),
                ToolbarButton(icon: Icons.delete, tooltip: PlaygroundCopy.clearGraph, onPressed: onClear),
                if (showZoomControls) ...[
                  ToolbarButton(icon: Icons.zoom_out, tooltip: PlaygroundCopy.zoomOut, onPressed: controller.zoomOut),
                  ListenableBuilder(listenable: controller, builder: _zoomLevel),
                  ToolbarButton(icon: Icons.zoom_in, tooltip: PlaygroundCopy.zoomIn, onPressed: controller.zoomIn),
                ],
              ],
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: null,
          onPressed: controller.centerGraph,
          tooltip: PlaygroundCopy.centerGraph,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          child: const Icon(Icons.zoom_in_map),
        ),
      ],
    );
  }

  IconData _generateIcon() {
    if (isAutoGenerating) return Icons.stop;
    return Icons.play_arrow;
  }

  String _generateTooltip() {
    if (isAutoGenerating) return PlaygroundCopy.stopGenerating;
    return PlaygroundCopy.generateNodes;
  }

  Widget _zoomLevel(BuildContext context, Widget? child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(PlaygroundCopy.zoomPercent(controller.scale), style: Theme.of(context).textTheme.labelMedium),
  );
}
