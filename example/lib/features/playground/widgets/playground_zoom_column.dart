import 'package:interactive_graphs_example/features/playground/models/playground_copy.dart';
import 'package:interactive_graphs_example/widgets/toolbar_button.dart';
import 'package:material_ui/material_ui.dart';

/// Zoom in and out buttons stacked in a floating card, for compact screens where the toolbar has
/// no room for them.
class PlaygroundZoomColumn extends StatelessWidget {
  /// Creates the buttons.
  const PlaygroundZoomColumn({super.key, required this.onZoomIn, required this.onZoomOut});

  /// Zooms in.
  final VoidCallback onZoomIn;

  /// Zooms out.
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 3,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ToolbarButton(icon: Icons.zoom_in, tooltip: PlaygroundCopy.zoomIn, onPressed: onZoomIn),
            ToolbarButton(icon: Icons.zoom_out, tooltip: PlaygroundCopy.zoomOut, onPressed: onZoomOut),
          ],
        ),
      ),
    );
  }
}
