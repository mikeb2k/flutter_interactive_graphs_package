import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/showcase/models/edge_state.dart';
import 'package:interactive_graphs_example/features/showcase/models/graph_focus.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_state.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_steps.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_graph.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/showcase_edge.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/step_node.dart';
import 'package:material_ui/material_ui.dart';

/// The order graph: step nodes and flow edges. Nodes and edges outside the hovered or selected
/// neighbourhood fade back.
class ShowcaseCanvas extends StatelessWidget {
  /// Creates the canvas.
  const ShowcaseCanvas({
    super.key,
    required this.controller,
    required this.state,
    required this.flowPhase,
    required this.config,
    required this.callbacks,
  });

  /// Controller of the viewer.
  final GraphViewerController controller;

  /// What the steps show.
  final ShowcaseState state;

  /// Phase of the parcels flowing along edges.
  final Animation<double> flowPhase;

  /// Viewer configuration.
  final GraphViewerConfig config;

  /// What taps and long presses do.
  final GraphInteractionCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(listenable: controller.interaction, builder: _viewer);
  }

  Widget _viewer(BuildContext context, Widget? child) {
    final focus = GraphFocus.of(controller.interaction, controller.layoutedGraph.edges);
    final ports = StepGraph.ports(controller.graph);
    return GraphViewer(
      controller: controller,
      config: config,
      callbacks: callbacks,
      nodeBuilder: (context, details) => _node(details, focus, ports),
      edgeBuilder: (context, details) => _edge(context, details, focus),
    );
  }

  Widget _node(NodeDetails details, GraphFocus focus, Map<String, Set<String>> ports) {
    final id = details.node.id;
    final spec = ShowcaseSteps.allSteps[id];
    if (spec == null) return const SizedBox.shrink();
    return StepNode(
      spec: spec,
      status: state.statusOf(id),
      expanded: state.expanded.contains(id),
      leaving: state.leaving.contains(id),
      dimmed: focus.dimsNode(id),
      isSelected: details.isSelected,
      isHovered: details.isHovered,
      isDragging: details.isDragging,
      ports: ports[id] ?? const {},
      appearDelay: Duration(milliseconds: state.entranceDelays[id] ?? 0),
    );
  }

  Widget _edge(BuildContext context, EdgeDetails details, GraphFocus focus) {
    final scheme = Theme.of(context).colorScheme;
    final edge = details.edge;
    final loop = edge.type == EdgeType.back || edge.isSelfLoop;
    final spec = ShowcaseSteps.edgeSpecs[edge.id];
    return ShowcaseEdge(
      details: details,
      style: state.edgeStyle,
      color: loop ? scheme.tertiary : scheme.primary,
      idleColor: scheme.outline,
      state: EdgeState.of(edge, state.statuses),
      dashed: loop,
      emphasized: details.isSelected || details.isHovered,
      dimmed: focus.dimsEdge(edge),
      label: spec?.label,
      labelAt: spec?.labelAt ?? 0.5,
      flowPhase: flowPhase,
      duration: _edgeDuration(context),
    );
  }

  Duration _edgeDuration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return const Duration(milliseconds: 300);
  }
}
