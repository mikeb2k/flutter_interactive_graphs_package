import 'package:interactive_graphs/src/layout/force_directed_layout.dart';
import 'package:interactive_graphs/src/layout/hierarchical_layout.dart';
import 'package:interactive_graphs/src/layout/layout_config.dart';
import 'package:interactive_graphs/src/model/graph.dart';

/// Thrown from a `checkCancelled` callback to abort a running layout.
final class LayoutCancelledException implements Exception {
  /// Creates the exception.
  const LayoutCancelledException();

  @override
  String toString() => 'LayoutCancelledException';
}

/// Runs the layout algorithm a [LayoutConfig] selects.
abstract final class GraphLayout {
  /// Returns [graph] with node positions computed by [config]'s algorithm and every edge
  /// classified.
  ///
  /// [checkCancelled] is polled during long layouts; throw [LayoutCancelledException] from it to
  /// abort.
  static Graph run(Graph graph, LayoutConfig config, {void Function()? checkCancelled}) => switch (config) {
    HierarchicalLayoutConfig() => HierarchicalLayout.run(graph, config),
    ForceDirectedLayoutConfig() => ForceDirectedLayout.run(graph, config, checkCancelled: checkCancelled),
    CustomLayoutConfig(:final provider) => provider(graph, config),
  };
}
