import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_test_copy.dart';
import 'package:material_ui/material_ui.dart';

/// A small spinner with "Laying out…" while a layout pass after the first one runs, e.g. on a
/// background isolate after switching the layout of a large graph. Empty otherwise.
class StressTestLayoutIndicator extends StatelessWidget {
  /// Creates the indicator.
  const StressTestLayoutIndicator({super.key, required this.controller});

  /// The viewer state to watch.
  final GraphViewerController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: controller, builder: _content);

  Widget _content(BuildContext context, Widget? child) {
    if (!controller.hasFittedInitially || !controller.isLayoutPending) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary)),
          const SizedBox(width: 6),
          Text(
            StressTestCopy.layingOut,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
