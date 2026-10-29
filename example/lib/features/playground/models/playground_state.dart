import 'package:flutter/foundation.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/edge_data.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_connection.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_edge_style.dart';
import 'package:interactive_graphs_example/models/layout_algorithm.dart';
import 'package:interactive_graphs_example/models/node_data.dart';

/// State of the playground: the graph, the app data of its nodes and edges, the view options, the
/// creation forms and connect mode.
@immutable
class PlaygroundState {
  /// Creates a state.
  const PlaygroundState({
    required this.graph,
    required this.nodeData,
    this.edgeData = const {},
    required this.nextNodeId,
    required this.nextEdgeId,
    this.layoutAlgorithm = LayoutAlgorithm.hierarchical,
    this.layoutDirection,
    this.edgeStyle = PlaygroundEdgeStyle.regular,
    this.showPorts = true,
    this.showDebugBounds = false,
    this.showNodeForm = false,
    this.showEdgeForm = false,
    this.newNodeLabel = '',
    this.newNodeColor,
    this.fromNodeLabel = '',
    this.toNodeLabel = '',
    this.newEdgeLabel = '',
    this.newEdgeLabelPosition = 0.5,
    this.isAutoGenerating = false,
    this.connection = PlaygroundConnection.none,
  });

  /// The graph, holding ids only; ports applied when [showPorts].
  final Graph graph;

  /// Label and color of every node, by node id.
  final Map<String, NodeData> nodeData;

  /// Label of labelled edges, by edge id.
  final Map<String, EdgeData> edgeData;

  /// Id of the next created node.
  final int nextNodeId;

  /// Number in the id of the next created edge (`e<n>`).
  final int nextEdgeId;

  /// Layout algorithm.
  final LayoutAlgorithm layoutAlgorithm;

  /// Direction of the hierarchical layout, `null` until picked: the screen then follows its
  /// orientation (vertical in portrait).
  final LayoutDirection? layoutDirection;

  /// How edges are drawn.
  final PlaygroundEdgeStyle edgeStyle;

  /// Whether every edge end has its own port on the node.
  final bool showPorts;

  /// Whether the viewer outlines the graph bounds and the viewport.
  final bool showDebugBounds;

  /// Whether the node creation form is open.
  final bool showNodeForm;

  /// Whether the edge creation form is open.
  final bool showEdgeForm;

  /// Label typed in the node form.
  final String newNodeLabel;

  /// Color picked in the node form, `null` for a random one.
  final NodeColorType? newNodeColor;

  /// Start node label typed in the edge form.
  final String fromNodeLabel;

  /// End node label typed in the edge form.
  final String toNodeLabel;

  /// Edge label typed in the edge form.
  final String newEdgeLabel;

  /// Label position picked in the edge form, `0` to `1`.
  final double newEdgeLabelPosition;

  /// Whether nodes and edges are added every second.
  final bool isAutoGenerating;

  /// Connect mode.
  final PlaygroundConnection connection;

  /// Layout direction, falling back to [orientationDirection] until one is picked.
  LayoutDirection directionOr(LayoutDirection orientationDirection) => layoutDirection ?? orientationDirection;

  /// Whether the graph flows top to bottom.
  bool isVertical(LayoutDirection orientationDirection) =>
      layoutAlgorithm == LayoutAlgorithm.hierarchical && directionOr(orientationDirection) == LayoutDirection.vertical;

  /// The layout configuration of the picked algorithm.
  LayoutConfig layoutConfig(LayoutDirection orientationDirection) => switch (layoutAlgorithm) {
    LayoutAlgorithm.hierarchical => LayoutConfig.hierarchical(direction: directionOr(orientationDirection)),
    LayoutAlgorithm.forceDirected => const LayoutConfig.forceDirected(),
  };

  /// Id of the node labelled [label], or `null`.
  String? nodeIdOf(String label) {
    for (final MapEntry(key: id, value: data) in nodeData.entries) {
      if (data.label == label) return id;
    }
    return null;
  }

  /// Returns a copy with the given fields replaced. [clearNewNodeColor] goes back to a random color.
  PlaygroundState copyWith({
    Graph? graph,
    Map<String, NodeData>? nodeData,
    Map<String, EdgeData>? edgeData,
    int? nextNodeId,
    int? nextEdgeId,
    LayoutAlgorithm? layoutAlgorithm,
    LayoutDirection? layoutDirection,
    PlaygroundEdgeStyle? edgeStyle,
    bool? showPorts,
    bool? showDebugBounds,
    bool? showNodeForm,
    bool? showEdgeForm,
    String? newNodeLabel,
    NodeColorType? newNodeColor,
    bool clearNewNodeColor = false,
    String? fromNodeLabel,
    String? toNodeLabel,
    String? newEdgeLabel,
    double? newEdgeLabelPosition,
    bool? isAutoGenerating,
    PlaygroundConnection? connection,
  }) => PlaygroundState(
    graph: graph ?? this.graph,
    nodeData: nodeData ?? this.nodeData,
    edgeData: edgeData ?? this.edgeData,
    nextNodeId: nextNodeId ?? this.nextNodeId,
    nextEdgeId: nextEdgeId ?? this.nextEdgeId,
    layoutAlgorithm: layoutAlgorithm ?? this.layoutAlgorithm,
    layoutDirection: layoutDirection ?? this.layoutDirection,
    edgeStyle: edgeStyle ?? this.edgeStyle,
    showPorts: showPorts ?? this.showPorts,
    showDebugBounds: showDebugBounds ?? this.showDebugBounds,
    showNodeForm: showNodeForm ?? this.showNodeForm,
    showEdgeForm: showEdgeForm ?? this.showEdgeForm,
    newNodeLabel: newNodeLabel ?? this.newNodeLabel,
    newNodeColor: clearNewNodeColor ? null : newNodeColor ?? this.newNodeColor,
    fromNodeLabel: fromNodeLabel ?? this.fromNodeLabel,
    toNodeLabel: toNodeLabel ?? this.toNodeLabel,
    newEdgeLabel: newEdgeLabel ?? this.newEdgeLabel,
    newEdgeLabelPosition: newEdgeLabelPosition ?? this.newEdgeLabelPosition,
    isAutoGenerating: isAutoGenerating ?? this.isAutoGenerating,
    connection: connection ?? this.connection,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaygroundState &&
          other.graph == graph &&
          mapEquals(other.nodeData, nodeData) &&
          mapEquals(other.edgeData, edgeData) &&
          other.nextNodeId == nextNodeId &&
          other.nextEdgeId == nextEdgeId &&
          other.layoutAlgorithm == layoutAlgorithm &&
          other.layoutDirection == layoutDirection &&
          other.edgeStyle == edgeStyle &&
          other.showPorts == showPorts &&
          other.showDebugBounds == showDebugBounds &&
          other.showNodeForm == showNodeForm &&
          other.showEdgeForm == showEdgeForm &&
          other.newNodeLabel == newNodeLabel &&
          other.newNodeColor == newNodeColor &&
          other.fromNodeLabel == fromNodeLabel &&
          other.toNodeLabel == toNodeLabel &&
          other.newEdgeLabel == newEdgeLabel &&
          other.newEdgeLabelPosition == newEdgeLabelPosition &&
          other.isAutoGenerating == isAutoGenerating &&
          other.connection == connection;

  @override
  int get hashCode => Object.hashAll([
    graph,
    Object.hashAllUnordered(nodeData.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAllUnordered(edgeData.entries.map((e) => Object.hash(e.key, e.value))),
    nextNodeId,
    nextEdgeId,
    layoutAlgorithm,
    layoutDirection,
    edgeStyle,
    showPorts,
    showDebugBounds,
    showNodeForm,
    showEdgeForm,
    newNodeLabel,
    newNodeColor,
    fromNodeLabel,
    toNodeLabel,
    newEdgeLabel,
    newEdgeLabelPosition,
    isAutoGenerating,
    connection,
  ]);
}
