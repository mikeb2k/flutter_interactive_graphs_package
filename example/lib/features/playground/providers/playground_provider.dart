import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/edge_data.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_copy.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_edge_style.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_ports.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_state.dart';
import 'package:interactive_graphs_example/models/layout_algorithm.dart';
import 'package:interactive_graphs_example/models/node_data.dart';

/// State of the playground screen.
final playgroundProvider = NotifierProvider.autoDispose<PlaygroundNotifier, PlaygroundState>(PlaygroundNotifier.new);

/// Every edit of the playground: graph changes go through here so the ports stay up to date.
class PlaygroundNotifier extends Notifier<PlaygroundState> {
  /// Creates the notifier; [random] picks colors and auto-generated edges.
  PlaygroundNotifier({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// The four-node demo graph the screen starts with.
  static const Map<String, NodeData> initialNodeData = {
    '1': NodeData(label: PlaygroundCopy.startNode, colorType: NodeColorType.pink),
    '2': NodeData(label: PlaygroundCopy.processNode, colorType: NodeColorType.yellow),
    '3': NodeData(label: PlaygroundCopy.reviewNode, colorType: NodeColorType.green),
    '4': NodeData(label: PlaygroundCopy.endNode, colorType: NodeColorType.blue),
  };

  /// Edges of the demo graph.
  static const List<GraphEdge> initialEdges = [
    GraphEdge('1', '2', id: 'e1'),
    GraphEdge('1', '3', id: 'e2'),
    GraphEdge('2', '4', id: 'e3'),
    GraphEdge('3', '4', id: 'e4'),
  ];

  @override
  PlaygroundState build() => PlaygroundState(
    graph: Graph.build((g) {
      for (final id in initialNodeData.keys) {
        g.addNode(GraphNode(id));
      }
      initialEdges.forEach(g.addEdge);
    }).withPorts(),
    nodeData: initialNodeData,
    nextNodeId: initialNodeData.length + 1,
    nextEdgeId: initialEdges.length + 1,
  );

  // ---- View options ----------------------------------------------------------------------------

  /// Picks the layout algorithm.
  void setLayoutAlgorithm(LayoutAlgorithm algorithm) => state = state.copyWith(layoutAlgorithm: algorithm);

  /// Picks the direction of the hierarchical layout.
  void setLayoutDirection(LayoutDirection direction) => state = state.copyWith(layoutDirection: direction);

  /// Picks how edges are drawn.
  void setEdgeStyle(PlaygroundEdgeStyle style) => state = state.copyWith(edgeStyle: style);

  /// Gives every edge end its own port, or attaches edges to the node boundaries.
  void togglePorts() {
    final showPorts = !state.showPorts;
    state = state.copyWith(
      showPorts: showPorts,
      graph: _withPortSetting(state.graph, showPorts: showPorts),
    );
  }

  /// Shows or hides the debug bounds.
  void toggleDebugBounds() => state = state.copyWith(showDebugBounds: !state.showDebugBounds);

  // ---- Forms -----------------------------------------------------------------------------------

  /// Opens or closes the node form, closing the edge form when it opens.
  void toggleNodeForm() {
    final show = !state.showNodeForm;
    state = state.copyWith(showNodeForm: show, showEdgeForm: show ? false : null);
  }

  /// Opens or closes the edge form, closing the node form when it opens.
  void toggleEdgeForm() {
    final show = !state.showEdgeForm;
    state = state.copyWith(showEdgeForm: show, showNodeForm: show ? false : null);
  }

  /// Updates the label typed in the node form.
  void setNewNodeLabel(String label) => state = state.copyWith(newNodeLabel: label);

  /// Picks the color of new nodes, `null` for a random one.
  void setNewNodeColor(NodeColorType? color) =>
      state = state.copyWith(newNodeColor: color, clearNewNodeColor: color == null);

  /// Updates the start node label of the edge form.
  void setFromNodeLabel(String label) => state = state.copyWith(fromNodeLabel: label);

  /// Updates the end node label of the edge form.
  void setToNodeLabel(String label) => state = state.copyWith(toNodeLabel: label);

  /// Updates the edge label of the edge form.
  void setNewEdgeLabel(String label) => state = state.copyWith(newEdgeLabel: label);

  /// Updates the label position of the edge form.
  void setNewEdgeLabelPosition(double position) => state = state.copyWith(newEdgeLabelPosition: position);

  /// Adds the node of the node form (`Node <id>` when no label is typed) and clears the label.
  /// Returns `false`, changing nothing, when the label is taken.
  bool createNodeFromForm() {
    final typed = state.newNodeLabel.trim();
    final label = typed.isEmpty ? PlaygroundCopy.defaultNodeLabel('${state.nextNodeId}') : typed;
    if (state.nodeIdOf(label) != null) return false;
    _addNode(label, state.newNodeColor ?? _randomColor());
    state = state.copyWith(newNodeLabel: '');
    return true;
  }

  /// Adds the edge of the edge form between the nodes with the typed labels, with its label, and
  /// resets the form. Returns `false`, changing nothing, when a label matches no node.
  bool createEdgeFromForm() {
    final fromId = state.nodeIdOf(state.fromNodeLabel.trim());
    final toId = state.nodeIdOf(state.toNodeLabel.trim());
    if (fromId == null || toId == null) return false;
    final id = _addEdge(fromId, toId);
    final label = state.newEdgeLabel;
    state = state.copyWith(
      edgeData: {
        ...state.edgeData,
        if (label.trim().isNotEmpty) id: EdgeData(label: label, labelOffset: state.newEdgeLabelPosition),
      },
      fromNodeLabel: '',
      toNodeLabel: '',
      newEdgeLabel: '',
      newEdgeLabelPosition: 0.5,
    );
    return true;
  }

  // ---- Graph edits -----------------------------------------------------------------------------

  /// Connect mode: the first tapped node becomes the source, the second one gets an edge from it
  /// (itself included, which makes a self-loop).
  void tapNode(String nodeId) {
    final source = state.connection.sourceNodeId;
    if (source == null) {
      state = state.copyWith(connection: state.connection.start(nodeId));
      return;
    }
    if (state.graph.nodes.containsKey(source) && state.graph.nodes.containsKey(nodeId)) _addEdge(source, nodeId);
    state = state.copyWith(connection: state.connection.reset());
  }

  /// Leaves connect mode.
  void cancelConnection() => state = state.copyWith(connection: state.connection.reset());

  /// Removes node [nodeId] with its edges and leaves connect mode.
  void removeNode(String nodeId) {
    final graph = state.graph;
    final removedEdges = {
      for (final edge in graph.edges)
        if (edge.fromId == nodeId || edge.toId == nodeId) edge.id,
    };
    state = state.copyWith(
      graph: _commit(graph.withoutNode(nodeId)),
      nodeData: {...state.nodeData}..remove(nodeId),
      edgeData: {...state.edgeData}..removeWhere((id, _) => removedEdges.contains(id)),
      connection: state.connection.reset(),
    );
  }

  /// Removes every node and edge, and stops auto generation.
  void clearGraph() => state = state.copyWith(
    graph: Graph.empty(),
    nodeData: const {},
    edgeData: const {},
    isAutoGenerating: false,
    connection: state.connection.reset(),
  );

  /// Starts or stops adding nodes and edges every second.
  void toggleAutoGenerating() => state = state.copyWith(isAutoGenerating: !state.isAutoGenerating);

  /// One auto-generation step: adds a node in a random color when [addNode] (or with fewer than
  /// two nodes), otherwise connects two random nodes that are not connected in that direction yet.
  void autoGenerateStep({required bool addNode}) {
    final graph = state.graph;
    if (addNode || graph.nodes.length < 2) {
      _addNode(PlaygroundCopy.defaultNodeLabel('${state.nextNodeId}'), _randomColor());
      return;
    }
    final ids = graph.nodes.keys.toList();
    final from = ids[_random.nextInt(ids.length)];
    final others = [
      for (final id in ids)
        if (id != from) id,
    ];
    final to = others[_random.nextInt(others.length)];
    if (graph.edgesBetween(from, to).isEmpty) _addEdge(from, to);
  }

  void _addNode(String label, NodeColorType color) {
    final id = '${state.nextNodeId}';
    state = state.copyWith(
      nextNodeId: state.nextNodeId + 1,
      nodeData: {
        ...state.nodeData,
        id: NodeData(label: label, colorType: color),
      },
      graph: _commit(state.graph.withNode(GraphNode(id))),
    );
  }

  String _addEdge(String fromId, String toId) {
    final id = 'e${state.nextEdgeId}';
    state = state.copyWith(
      nextEdgeId: state.nextEdgeId + 1,
      graph: _commit(state.graph.withEdge(GraphEdge(fromId, toId, id: id))),
    );
    return id;
  }

  NodeColorType _randomColor() => NodeColorType.values[_random.nextInt(NodeColorType.values.length)];

  /// Applies every edit through here to update the ports.
  Graph _commit(Graph graph) => _withPortSetting(graph, showPorts: state.showPorts);

  Graph _withPortSetting(Graph graph, {required bool showPorts}) {
    if (showPorts) return graph.withPorts();
    return graph.withoutPorts();
  }
}
