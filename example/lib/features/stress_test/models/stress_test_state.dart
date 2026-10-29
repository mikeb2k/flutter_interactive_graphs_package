import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_graph.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_preset.dart';
import 'package:interactive_graphs_example/models/layout_algorithm.dart';
import 'package:material_ui/material_ui.dart';

/// State of the stress test screen.
@immutable
class StressTestState {
  /// Creates the state.
  const StressTestState({
    required this.preset,
    required this.layoutAlgorithm,
    required this.seed,
    required this.stressGraph,
    this.showDebugBounds = false,
    this.batchedEdges = false,
    this.toolbarExpanded = false,
  });

  /// The initial state: 100 nodes, force-directed layout, seed 0.
  factory StressTestState.initial() {
    const preset = StressPreset.medium;
    return StressTestState(
      preset: preset,
      layoutAlgorithm: LayoutAlgorithm.forceDirected,
      seed: 0,
      stressGraph: StressGraph.generate(nodeCount: preset.nodeCount, seed: 0),
    );
  }

  /// Selected graph size.
  final StressPreset preset;

  /// Selected layout algorithm.
  final LayoutAlgorithm layoutAlgorithm;

  /// Seed of the generated graph; regenerating increments it.
  final int seed;

  /// The generated graph for [preset] and [seed].
  final StressGraph stressGraph;

  /// Whether the viewer draws its debug bounds.
  final bool showDebugBounds;

  /// Whether edges are painted in one batched layer instead of one widget each.
  final bool batchedEdges;

  /// Whether the zoom toolbar is expanded.
  final bool toolbarExpanded;

  /// Layout configuration of [layoutAlgorithm].
  LayoutConfig get layoutConfig => switch (layoutAlgorithm) {
    LayoutAlgorithm.hierarchical => const LayoutConfig.hierarchical(direction: LayoutDirection.horizontal),
    LayoutAlgorithm.forceDirected => const LayoutConfig.forceDirected(),
  };

  /// Returns a copy with the given fields replaced.
  StressTestState copyWith({
    StressPreset? preset,
    LayoutAlgorithm? layoutAlgorithm,
    int? seed,
    StressGraph? stressGraph,
    bool? showDebugBounds,
    bool? batchedEdges,
    bool? toolbarExpanded,
  }) => StressTestState(
    preset: preset ?? this.preset,
    layoutAlgorithm: layoutAlgorithm ?? this.layoutAlgorithm,
    seed: seed ?? this.seed,
    stressGraph: stressGraph ?? this.stressGraph,
    showDebugBounds: showDebugBounds ?? this.showDebugBounds,
    batchedEdges: batchedEdges ?? this.batchedEdges,
    toolbarExpanded: toolbarExpanded ?? this.toolbarExpanded,
  );

  @override
  bool operator ==(Object other) =>
      other is StressTestState &&
      other.preset == preset &&
      other.layoutAlgorithm == layoutAlgorithm &&
      other.seed == seed &&
      other.stressGraph == stressGraph &&
      other.showDebugBounds == showDebugBounds &&
      other.batchedEdges == batchedEdges &&
      other.toolbarExpanded == toolbarExpanded;

  @override
  int get hashCode =>
      Object.hash(preset, layoutAlgorithm, seed, stressGraph, showDebugBounds, batchedEdges, toolbarExpanded);
}
