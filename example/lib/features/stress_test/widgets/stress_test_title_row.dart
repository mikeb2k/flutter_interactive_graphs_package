import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_test_copy.dart';
import 'package:interactive_graphs_example/features/stress_test/widgets/stress_test_layout_indicator.dart';
import 'package:interactive_graphs_example/widgets/toolbar_button.dart';
import 'package:material_ui/material_ui.dart';

/// Back button, title with node and edge counts, regenerate and debug bounds buttons.
class StressTestTitleRow extends StatelessWidget {
  /// Creates the row.
  const StressTestTitleRow({
    super.key,
    required this.controller,
    required this.nodeCount,
    required this.edgeCount,
    required this.showDebugBounds,
    required this.onToggleDebugBounds,
    required this.onRegenerate,
    required this.onNavigateBack,
  });

  /// The viewer state, for the layout indicator.
  final GraphViewerController controller;

  /// Number of nodes.
  final int nodeCount;

  /// Number of edges.
  final int edgeCount;

  /// Whether the debug bounds are shown.
  final bool showDebugBounds;

  /// Shows or hides the debug bounds.
  final VoidCallback onToggleDebugBounds;

  /// Generates a new graph.
  final VoidCallback onRegenerate;

  /// Leaves the screen.
  final VoidCallback onNavigateBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        ToolbarButton(icon: Icons.arrow_back, tooltip: StressTestCopy.back, onPressed: onNavigateBack),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(StressTestCopy.title, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    StressTestCopy.stats(nodeCount, edgeCount),
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  StressTestLayoutIndicator(controller: controller),
                ],
              ),
            ],
          ),
        ),
        ToolbarButton(icon: Icons.refresh, tooltip: StressTestCopy.regenerate, onPressed: onRegenerate),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          isSelected: showDebugBounds,
          tooltip: StressTestCopy.toggleDebugBounds,
          onPressed: onToggleDebugBounds,
        ),
      ],
    );
  }
}
