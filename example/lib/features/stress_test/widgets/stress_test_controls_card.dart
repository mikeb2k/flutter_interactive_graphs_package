import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_preset.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_test_copy.dart';
import 'package:interactive_graphs_example/features/stress_test/widgets/stress_test_option_row.dart';
import 'package:interactive_graphs_example/features/stress_test/widgets/stress_test_title_row.dart';
import 'package:interactive_graphs_example/models/layout_algorithm.dart';
import 'package:interactive_graphs_example/widgets/connected_toggle_group.dart';
import 'package:material_ui/material_ui.dart';

/// The card on top of the stress test: title and actions, node count picker, layout picker and
/// the batched edges toggle. Its rows wrap on narrow screens.
class StressTestControlsCard extends StatelessWidget {
  /// Creates the card.
  const StressTestControlsCard({
    super.key,
    required this.controller,
    required this.selectedPreset,
    required this.onPresetSelected,
    required this.selectedLayoutAlgorithm,
    required this.onLayoutAlgorithmSelected,
    required this.nodeCount,
    required this.edgeCount,
    required this.showDebugBounds,
    required this.onToggleDebugBounds,
    required this.batchedEdges,
    required this.onToggleBatchedEdges,
    required this.onRegenerate,
    required this.onNavigateBack,
  });

  /// The viewer state, for the layout indicator.
  final GraphViewerController controller;

  /// Selected graph size.
  final StressPreset selectedPreset;

  /// Picks a graph size.
  final ValueChanged<StressPreset> onPresetSelected;

  /// Selected layout algorithm.
  final LayoutAlgorithm selectedLayoutAlgorithm;

  /// Picks a layout algorithm.
  final ValueChanged<LayoutAlgorithm> onLayoutAlgorithmSelected;

  /// Number of nodes.
  final int nodeCount;

  /// Number of edges.
  final int edgeCount;

  /// Whether the debug bounds are shown.
  final bool showDebugBounds;

  /// Shows or hides the debug bounds.
  final VoidCallback onToggleDebugBounds;

  /// Whether edges are painted in one batched layer.
  final bool batchedEdges;

  /// Switches the edge rendering.
  final VoidCallback onToggleBatchedEdges;

  /// Generates a new graph.
  final VoidCallback onRegenerate;

  /// Leaves the screen.
  final VoidCallback onNavigateBack;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StressTestTitleRow(
              controller: controller,
              nodeCount: nodeCount,
              edgeCount: edgeCount,
              showDebugBounds: showDebugBounds,
              onToggleDebugBounds: onToggleDebugBounds,
              onRegenerate: onRegenerate,
              onNavigateBack: onNavigateBack,
            ),
            StressTestOptionRow(
              label: StressTestCopy.nodes,
              children: [
                ConnectedToggleGroup<StressPreset>(
                  options: StressPreset.values,
                  selected: selectedPreset,
                  label: StressTestCopy.preset,
                  onSelect: onPresetSelected,
                ),
              ],
            ),
            StressTestOptionRow(
              label: StressTestCopy.layout,
              children: [
                ConnectedToggleGroup<LayoutAlgorithm>(
                  options: LayoutAlgorithm.values,
                  selected: selectedLayoutAlgorithm,
                  label: StressTestCopy.layoutAlgorithm,
                  onSelect: onLayoutAlgorithmSelected,
                ),
                FilterChip(
                  label: const Text(StressTestCopy.batchedEdges),
                  selected: batchedEdges,
                  onSelected: _onBatchedSelected,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onBatchedSelected(bool _) => onToggleBatchedEdges();
}
