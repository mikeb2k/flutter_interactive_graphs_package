import 'package:flutter/foundation.dart';

/// Classification of an edge relative to a depth-first traversal of its graph, used for styling
/// and layout decisions.
enum EdgeType {
  /// Points to a descendant in the graph hierarchy.
  forward,

  /// Points back to an ancestor and closes a cycle.
  back,

  /// Connects nodes in different branches.
  cross,

  /// Starts and ends at the same node.
  selfLoop,
}

/// A directed edge from [fromId] to [toId], optionally between named anchors of the two nodes.
///
/// A graph holds one edge per [id]. Edges with the default id (`"$fromId->$toId"`) connect two
/// nodes at most once per direction; give edges explicit ids to connect the same nodes several
/// times:
///
/// ```dart
/// const GraphEdge('A', 'B', id: 'primary');
/// const GraphEdge('A', 'B', id: 'fallback');
/// ```
@immutable
final class GraphEdge {
  /// Creates an edge. [id] defaults to `"$fromId->$toId"`.
  const GraphEdge(this.fromId, this.toId, {this.type, this.fromAnchor, this.toAnchor, String? id})
    : id = id ?? '$fromId->$toId';

  /// Id of the start node.
  final String fromId;

  /// Id of the end node.
  final String toId;

  /// Classification computed by the layout, `null` until the graph is laid out.
  final EdgeType? type;

  /// Anchor id on the start node (see `GraphAnchor`), or `null` to attach to the node's boundary.
  final String? fromAnchor;

  /// Anchor id on the end node, or `null` to attach to the node's boundary.
  final String? toAnchor;

  /// Identity of the edge within a graph. [copyWith] keeps it; pass a new one when changing the
  /// endpoints.
  final String id;

  /// Whether the edge starts and ends at the same node.
  bool get isSelfLoop => fromId == toId;

  /// Returns a copy with the given fields replaced. The [id] is kept unless a new one is passed.
  GraphEdge copyWith({
    String? fromId,
    String? toId,
    EdgeType? type,
    String? fromAnchor,
    String? toAnchor,
    String? id,
  }) => GraphEdge(
    fromId ?? this.fromId,
    toId ?? this.toId,
    type: type ?? this.type,
    fromAnchor: fromAnchor ?? this.fromAnchor,
    toAnchor: toAnchor ?? this.toAnchor,
    id: id ?? this.id,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphEdge &&
          other.fromId == fromId &&
          other.toId == toId &&
          other.type == type &&
          other.fromAnchor == fromAnchor &&
          other.toAnchor == toAnchor &&
          other.id == id;

  @override
  int get hashCode => Object.hash(fromId, toId, type, fromAnchor, toAnchor, id);

  @override
  String toString() => 'GraphEdge($id: $fromId -> $toId${type == null ? '' : ', $type'})';
}
