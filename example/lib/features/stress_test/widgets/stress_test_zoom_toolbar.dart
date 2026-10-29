import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_test_copy.dart';
import 'package:interactive_graphs_example/widgets/toolbar_button.dart';
import 'package:material_ui/material_ui.dart';

/// Floating toolbar with a button that expands it into center, zoom out, zoom level and zoom in.
class StressTestZoomToolbar extends StatelessWidget {
  /// Creates the toolbar.
  const StressTestZoomToolbar({
    super.key,
    required this.controller,
    required this.expanded,
    required this.onToggleExpanded,
  });

  /// The viewer state to control.
  final GraphViewerController controller;

  /// Whether the zoom controls are shown.
  final bool expanded;

  /// Expands or collapses the toolbar.
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 3,
      shape: const StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: _sizeDuration(context),
              curve: Curves.easeOutCubic,
              child: _controls(context),
            ),
            FloatingActionButton(
              heroTag: null,
              elevation: 0,
              tooltip: StressTestCopy.zoomControls,
              onPressed: onToggleExpanded,
              child: const Icon(Icons.zoom_in_map),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    if (!expanded) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            child: IconButton.filled(
              icon: const Icon(Icons.zoom_in_map),
              tooltip: StressTestCopy.centerGraph,
              onPressed: controller.centerGraph,
            ),
          ),
          const SizedBox(width: 8),
          ToolbarButton(icon: Icons.zoom_out, tooltip: StressTestCopy.zoomOut, onPressed: controller.zoomOut),
          ListenableBuilder(listenable: controller, builder: _zoomLevel),
          ToolbarButton(icon: Icons.zoom_in, tooltip: StressTestCopy.zoomIn, onPressed: controller.zoomIn),
        ],
      ),
    );
  }

  Widget _zoomLevel(BuildContext context, Widget? child) => Padding(
    padding: const EdgeInsets.all(4),
    child: Text(
      StressTestCopy.zoomPercent(controller.scale),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
    ),
  );

  Duration _sizeDuration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return const Duration(milliseconds: 200);
  }
}
