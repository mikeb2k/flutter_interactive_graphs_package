import 'package:flutter/foundation.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

/// The node or edge that has the focus (hovered, or else the single selection) and the nodes
/// around it. Everything else fades back.
@immutable
class GraphFocus {
  /// Creates a focus.
  const GraphFocus({this.nodeId, this.edgeId, this.related});

  /// Focus of [interaction] in a graph with [edges].
  factory GraphFocus.of(GraphInteraction interaction, Iterable<GraphEdge> edges) {
    final nodeId = interaction.hoveredNodeId ?? interaction.selectedNodeIds.singleOrNull;
    if (nodeId != null) {
      return GraphFocus(
        nodeId: nodeId,
        related: {
          nodeId,
          for (final edge in edges)
            if (edge.fromId == nodeId || edge.toId == nodeId) ...[edge.fromId, edge.toId],
        },
      );
    }
    final edgeId = interaction.hoveredEdgeId ?? interaction.selectedEdgeIds.singleOrNull;
    if (edgeId == null) return const GraphFocus();
    final edge = edges.where((edge) => edge.id == edgeId).firstOrNull;
    return GraphFocus(edgeId: edgeId, related: edge == null ? null : {edge.fromId, edge.toId});
  }

  /// Focused node.
  final String? nodeId;

  /// Focused edge, when no node has the focus.
  final String? edgeId;

  /// Nodes that stay in front, or `null` when nothing has the focus.
  final Set<String>? related;

  /// Whether node [id] fades back.
  bool dimsNode(String id) => related?.contains(id) == false;

  /// Whether [edge] fades back.
  bool dimsEdge(GraphEdge edge) {
    final node = nodeId;
    if (node != null) return edge.fromId != node && edge.toId != node;
    final focused = edgeId;
    return focused != null && edge.id != focused;
  }

  @override
  bool operator ==(Object other) =>
      other is GraphFocus && other.nodeId == nodeId && other.edgeId == edgeId && setEquals(other.related, related);

  @override
  int get hashCode => Object.hash(nodeId, edgeId, related == null ? null : Object.hashAllUnordered(related!));
}
