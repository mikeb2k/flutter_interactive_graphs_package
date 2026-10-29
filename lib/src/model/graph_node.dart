import 'dart:ui';

import 'package:flutter/foundation.dart';

/// A node of a [Graph], identified by [id].
///
/// The package only handles the visual structure: keep your own data elsewhere and look it up by
/// [id] in the viewer's `nodeBuilder`.
@immutable
final class GraphNode {
  /// Creates a node.
  ///
  /// Leave [size] `null` to have the viewer measure the node's widget; set it to give the node a
  /// fixed box that its widget is laid out in.
  const GraphNode(this.id, {this.size, this.position = Offset.zero});

  /// Unique identifier within a graph.
  final String id;

  /// Fixed size of the node in logical pixels, or `null` to measure the node's widget.
  final Size? size;

  /// Center of the node in graph space (logical pixels). Written by the layout algorithms.
  final Offset position;

  /// Returns a copy with the given fields replaced. Use [withSize] to clear [size].
  GraphNode copyWith({Size? size, Offset? position}) =>
      GraphNode(id, size: size ?? this.size, position: position ?? this.position);

  /// Returns a copy with [size] replaced, `null` included.
  GraphNode withSize(Size? size) => GraphNode(id, size: size, position: position);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphNode && other.id == id && other.size == size && other.position == position;

  @override
  int get hashCode => Object.hash(id, size, position);

  @override
  String toString() => 'GraphNode($id, size: $size, position: $position)';
}
