import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_node_data.dart';
import 'package:interactive_graphs_example/features/stress_test/widgets/stress_node.dart';
import 'package:material_ui/material_ui.dart';

/// The stress test graph: [StressNode]s, with edges either painted in one batched layer or built
/// as one [StyledEdge] widget each.
class StressTestGraphViewer extends StatelessWidget {
  /// Creates the viewer.
  const StressTestGraphViewer({
    super.key,
    required this.controller,
    required this.nodeData,
    required this.showDebugBounds,
    required this.batchedEdges,
  });

  /// State of the viewer.
  final GraphViewerController controller;

  /// Data of every node, by node id.
  final Map<String, StressNodeData> nodeData;

  /// Whether to draw the debug bounds.
  final bool showDebugBounds;

  /// Whether edges are painted in one batched layer.
  final bool batchedEdges;

  @override
  Widget build(BuildContext context) {
    final theme = GraphTheme.of(context);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: GraphViewer(
        controller: controller,
        config: GraphViewerConfig(showDebugBounds: showDebugBounds),
        nodeBuilder: _node,
        edgeBuilder: _edgeBuilder,
        edgeStyle: (details) =>
            EdgeStyle.styled(details.edge, baseColor: theme.edgeColor, backEdgeColor: theme.backEdgeColor),
      ),
    );
  }

  Widget _node(BuildContext context, NodeDetails details) => switch (nodeData[details.node.id]) {
    final data? => StressNode(data: data),
    null => const SizedBox.shrink(),
  };

  GraphEdgeBuilder? get _edgeBuilder => switch (batchedEdges) {
    true => null,
    false => _edge,
  };

  Widget _edge(BuildContext context, EdgeDetails details) => StyledEdge(details: details);
}
