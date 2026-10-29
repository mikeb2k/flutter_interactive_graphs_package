import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_test_copy.dart';
import 'package:material_ui/material_ui.dart';

/// Covers the viewer with a spinner and "Calculating layout…" until the graph has been laid out
/// and fitted once, then fades out. Appears instantly for a new graph.
class StressTestLoadingOverlay extends StatelessWidget {
  /// Creates the overlay.
  const StressTestLoadingOverlay({super.key, required this.controller});

  /// The viewer state to watch.
  final GraphViewerController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: controller, builder: _content);

  Widget _content(BuildContext context, Widget? child) {
    final visible = !controller.hasFittedInitially;
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: _opacity(visible),
        duration: _duration(context, visible),
        child: ColoredBox(
          color: scheme.surface,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    StressTestCopy.calculatingLayout,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _opacity(bool visible) => switch (visible) {
    true => 1,
    false => 0,
  };

  /// No enter animation; a short fade out unless animations are disabled.
  Duration _duration(BuildContext context, bool visible) {
    if (visible || MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return const Duration(milliseconds: 300);
  }
}
