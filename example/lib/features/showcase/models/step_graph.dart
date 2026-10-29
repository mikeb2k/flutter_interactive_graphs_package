import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_layout.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_steps.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_spec.dart';

/// Builds the showcase graph from the visible steps.
abstract final class StepGraph {
  /// The graph of [visibleIds], with ports matching the flow of [layout].
  ///
  /// Forward edges leave the node on the side facing the flow, loops use the top (or right) side,
  /// layouts without a flow direction use no anchors.
  static Graph build(List<String> visibleIds, ShowcaseLayout layout) {
    final visible = visibleIds.toSet();
    final specs = [
      ...ShowcaseSteps.orderEdges,
      for (final id in visibleIds) ...ShowcaseSteps.extraStepEdges(id),
    ].where((spec) => visible.contains(spec.from) && visible.contains(spec.to)).toList();
    // Loops go in last so that the edge classification agrees with them
    final ordered = [...specs.where((spec) => !spec.loop), ...specs.where((spec) => spec.loop)];

    return Graph.build((g) {
      visibleIds.forEach(g.node);
      for (final spec in ordered) {
        final (fromAnchor, toAnchor) = anchorsOf(spec, layout);
        g.edge(spec.from, spec.to, fromAnchor: fromAnchor, toAnchor: toAnchor, id: spec.id);
      }
    });
  }

  /// Start and end anchor of [spec] in [layout].
  static (String?, String?) anchorsOf(EdgeSpec spec, ShowcaseLayout layout) => switch (layout) {
    _ when spec.from == spec.to => (null, null),
    ShowcaseLayout.flow when spec.loop => ('top', 'top'),
    ShowcaseLayout.flow => ('right', 'left'),
    ShowcaseLayout.stack when spec.loop => ('right', 'right'),
    ShowcaseLayout.stack => ('bottom', 'top'),
    ShowcaseLayout.organic || ShowcaseLayout.orbit => (null, null),
  };

  /// Anchor ids edges of [graph] attach to, by node id.
  static Map<String, Set<String>> ports(Graph graph) {
    final ports = <String, Set<String>>{};
    for (final edge in graph.edges) {
      if (edge.fromAnchor case final anchor?) ports.putIfAbsent(edge.fromId, () => {}).add(anchor);
      if (edge.toAnchor case final anchor?) ports.putIfAbsent(edge.toId, () => {}).add(anchor);
    }
    return ports;
  }
}
