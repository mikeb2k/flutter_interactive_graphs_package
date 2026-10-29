import 'package:interactive_graphs_example/features/showcase/models/showcase_copy.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_metrics.dart';
import 'package:interactive_graphs_example/widgets/toolbar_button.dart';
import 'package:material_ui/material_ui.dart';

/// Floating toolbar under the graph: add a step, zoom, fit, reset, and a button that plays the
/// order through.
class ShowcaseToolbar extends StatelessWidget {
  /// Creates the toolbar.
  const ShowcaseToolbar({
    super.key,
    required this.isRunning,
    required this.onToggleRun,
    required this.onAddStep,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onFit,
    required this.onReset,
  });

  /// Whether the order is playing.
  final bool isRunning;

  /// Plays or stops the order.
  final VoidCallback onToggleRun;

  /// Adds the next extra step.
  final VoidCallback onAddStep;

  /// Zooms out.
  final VoidCallback onZoomOut;

  /// Zooms in.
  final VoidCallback onZoomIn;

  /// Fits the graph.
  final VoidCallback onFit;

  /// Back to the plain order.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      shape: const StadiumBorder(),
      elevation: 3,
      child: SizedBox(
        height: ShowcaseMetrics.toolbarHeight,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButtonTheme(
                data: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: scheme.onPrimaryContainer)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ToolbarButton(icon: Icons.add, tooltip: ShowcaseCopy.addStep, onPressed: onAddStep),
                    ToolbarButton(icon: Icons.zoom_out, tooltip: ShowcaseCopy.zoomOut, onPressed: onZoomOut),
                    ToolbarButton(icon: Icons.zoom_in, tooltip: ShowcaseCopy.zoomIn, onPressed: onZoomIn),
                    ToolbarButton(icon: Icons.zoom_in_map, tooltip: ShowcaseCopy.fitGraph, onPressed: onFit),
                    ToolbarButton(icon: Icons.refresh, tooltip: ShowcaseCopy.reset, onPressed: onReset),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              FloatingActionButton(
                heroTag: null,
                elevation: 0,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                tooltip: _runLabel(),
                onPressed: onToggleRun,
                child: Icon(_runIcon()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _runIcon() {
    if (isRunning) return Icons.stop;
    return Icons.play_arrow;
  }

  String _runLabel() {
    if (isRunning) return ShowcaseCopy.stopOrder;
    return ShowcaseCopy.playOrder;
  }
}
