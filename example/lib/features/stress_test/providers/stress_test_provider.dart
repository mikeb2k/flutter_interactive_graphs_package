import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_graph.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_preset.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_test_state.dart';
import 'package:interactive_graphs_example/models/layout_algorithm.dart';

/// State of the stress test screen.
final stressTestProvider = NotifierProvider.autoDispose<StressTestNotifier, StressTestState>(StressTestNotifier.new);

/// Changes the stress test settings and regenerates the graph when its size or seed change.
class StressTestNotifier extends Notifier<StressTestState> {
  @override
  StressTestState build() => StressTestState.initial();

  /// Switches to [preset] and generates a graph of that size.
  void selectPreset(StressPreset preset) {
    if (preset == state.preset) return;
    state = state.copyWith(
      preset: preset,
      stressGraph: StressGraph.generate(nodeCount: preset.nodeCount, seed: state.seed),
    );
  }

  /// Switches the layout algorithm.
  void selectLayoutAlgorithm(LayoutAlgorithm algorithm) => state = state.copyWith(layoutAlgorithm: algorithm);

  /// Generates a new graph of the same size with the next seed.
  void regenerate() {
    final seed = state.seed + 1;
    state = state.copyWith(
      seed: seed,
      stressGraph: StressGraph.generate(nodeCount: state.preset.nodeCount, seed: seed),
    );
  }

  /// Shows or hides the viewer's debug bounds.
  void toggleDebugBounds() => state = state.copyWith(showDebugBounds: !state.showDebugBounds);

  /// Switches between batched edge painting and one widget per edge.
  void toggleBatchedEdges() => state = state.copyWith(batchedEdges: !state.batchedEdges);

  /// Expands or collapses the zoom toolbar.
  void toggleToolbar() => state = state.copyWith(toolbarExpanded: !state.toolbarExpanded);
}
