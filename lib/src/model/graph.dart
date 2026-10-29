import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:interactive_graphs/src/model/graph_edge.dart';
import 'package:interactive_graphs/src/model/graph_node.dart';

/// Immutable directed graph that supports cycles, self-loops and parallel edges.
///
/// Create one with [Graph.build] and derive new ones with [withNode], [withNodes], [withEdge],
/// [withEdges], [withoutNode], [withoutEdge] or [rebuild]. Graphs compare structurally: a graph
/// with the same nodes and edges is equal, and a change that changes nothing returns the same
/// instance.
///
/// Nodes are unique by id and edges by [GraphEdge.id]. Iteration follows insertion order.
///
/// ```dart
/// final graph = Graph.build((g) => g
///   ..nodes(['A', 'B', 'C'])
///   ..edges([('A', 'B'), ('B', 'C')]));
/// ```
@immutable
final class Graph {
  Graph._(
    Map<String, GraphNode> nodes,
    Set<GraphEdge> edges,
    Map<String, Set<String>> adjacency,
    Map<String, GraphEdge> edgeMap,
  ) : nodes = UnmodifiableMapView(nodes),
      edges = UnmodifiableSetView(edges),
      _adjacency = adjacency,
      _edgeMap = edgeMap;

  /// An empty graph.
  factory Graph.empty() => GraphBuilder().build();

  /// Builds a graph by running [block] on a fresh [GraphBuilder].
  static Graph build(void Function(GraphBuilder g) block) {
    final builder = GraphBuilder();
    block(builder);
    return builder.build();
  }

  /// Builds a graph from [nodes] and [edges] and stores the [EdgeType] of every edge, as layouts
  /// do with their result. Use it at the end of a custom layout.
  static Graph withClassifiedEdges(Iterable<GraphNode> nodes, Iterable<GraphEdge> edges) {
    final unclassified = Graph.build((g) {
      nodes.forEach(g.addNode);
      edges.forEach(g.addEdge);
    });
    return unclassified._withEdgeTypes(unclassified.classifyAllEdges());
  }

  /// Nodes by id, in insertion order. Unmodifiable.
  final Map<String, GraphNode> nodes;

  /// Edges in insertion order. Unmodifiable.
  final Set<GraphEdge> edges;

  final Map<String, Set<String>> _adjacency;
  final Map<String, GraphEdge> _edgeMap;

  late final int _hashCode = Object.hash(Object.hashAllUnordered(nodes.values), Object.hashAllUnordered(edges));

  late final Map<(String, String), List<GraphEdge>> _edgesByPair = () {
    final byPair = <(String, String), List<GraphEdge>>{};
    for (final edge in edges) {
      byPair.putIfAbsent((edge.fromId, edge.toId), () => []).add(edge);
    }
    return byPair;
  }();

  /// Whether any two edges share their start and end node.
  bool get hasParallelEdges => _adjacency.values.fold(0, (sum, targets) => sum + targets.length) < edges.length;

  /// The edge with [id], or `null`.
  GraphEdge? edge(String id) => _edgeMap[id];

  /// Returns the edges from [fromId] to [toId] in insertion order. The opposite direction is not
  /// included.
  List<GraphEdge> edgesBetween(String fromId, String toId) =>
      List.unmodifiable(_edgesByPair[(fromId, toId)] ?? const <GraphEdge>[]);

  /// Returns a copy with [node] added, replacing a node with the same id. Edges are untouched,
  /// which makes this the way to update a node's position or size.
  Graph withNode(GraphNode node) {
    if (nodes[node.id] == node) return this;
    final adjacency = _adjacency.containsKey(node.id) ? _adjacency : {..._adjacency, node.id: <String>{}};
    return Graph._({...nodes, node.id: node}, edges, adjacency, _edgeMap);
  }

  /// Returns a copy with all of [newNodes] added, replacing nodes with the same ids.
  Graph withNodes(Iterable<GraphNode> newNodes) {
    if (newNodes.isEmpty) return this;
    final updatedNodes = {...nodes};
    final updatedAdjacency = {..._adjacency};
    for (final node in newNodes) {
      updatedNodes[node.id] = node;
      updatedAdjacency.putIfAbsent(node.id, () => <String>{});
    }
    if (mapEquals(updatedNodes, nodes)) return this;
    return Graph._(updatedNodes, edges, updatedAdjacency, _edgeMap);
  }

  /// Returns a copy with [edge] added.
  ///
  /// A graph holds at most one edge per [GraphEdge.id]: if the id is taken, this returns the graph
  /// unchanged. Remove the existing edge with [withoutEdge] first to replace it.
  ///
  /// Throws an [ArgumentError] if an endpoint is not in the graph, or if the id already belongs to
  /// an edge between other nodes.
  Graph withEdge(GraphEdge edge) {
    _requireEndpoints(edge);
    final existing = _edgeMap[edge.id];
    if (existing != null) {
      existing._requireSameEndpoints(edge);
      return this;
    }
    return Graph._(
      nodes,
      {...edges, edge},
      {
        ..._adjacency,
        edge.fromId: {...?_adjacency[edge.fromId], edge.toId},
      },
      {..._edgeMap, edge.id: edge},
    );
  }

  /// Returns a copy with all of [newEdges] added, skipping ids that are already taken. See
  /// [withEdge].
  Graph withEdges(Iterable<GraphEdge> newEdges) {
    if (newEdges.isEmpty) return this;
    newEdges.forEach(_requireEndpoints);
    final updatedEdges = {...edges};
    final updatedAdjacency = {..._adjacency};
    final updatedEdgeMap = {..._edgeMap};
    for (final edge in newEdges) {
      final existing = updatedEdgeMap[edge.id];
      if (existing != null) {
        existing._requireSameEndpoints(edge);
        continue;
      }
      updatedEdges.add(edge);
      updatedAdjacency[edge.fromId] = {...?updatedAdjacency[edge.fromId], edge.toId};
      updatedEdgeMap[edge.id] = edge;
    }
    if (updatedEdges.length == edges.length) return this;
    return Graph._(nodes, updatedEdges, updatedAdjacency, updatedEdgeMap);
  }

  /// Returns a copy without the node [id] and without the edges touching it.
  Graph withoutNode(String id) {
    if (!nodes.containsKey(id)) return this;
    return Graph.build((g) {
      for (final node in nodes.values) {
        if (node.id != id) g.addNode(node);
      }
      for (final edge in edges) {
        if (edge.fromId != id && edge.toId != id) g.addEdge(edge);
      }
    });
  }

  /// Returns a copy without the edge [id]. Unknown ids are ignored.
  Graph withoutEdge(String id) {
    if (!_edgeMap.containsKey(id)) return this;
    return Graph.build((g) {
      nodes.values.forEach(g.addNode);
      for (final edge in edges) {
        if (edge.id != id) g.addEdge(edge);
      }
    });
  }

  /// Returns a copy with node sizes replaced by [sizes] where present.
  Graph withMeasuredSizes(Map<String, Size> sizes) {
    if (sizes.isEmpty) return this;
    var changed = false;
    final updated = <String, GraphNode>{};
    for (final MapEntry(key: id, value: node) in nodes.entries) {
      final size = sizes[id];
      if (size == null || size == node.size) {
        updated[id] = node;
      } else {
        changed = true;
        updated[id] = node.withSize(size);
      }
    }
    if (!changed) return this;
    return Graph._(updated, edges, _adjacency, _edgeMap);
  }

  /// Reopens this graph in a [GraphBuilder] and returns the result, for batches of changes.
  ///
  /// ```dart
  /// final extended = graph.rebuild((g) => g
  ///   ..nodes(['D'])
  ///   ..edge('C', 'D'));
  /// ```
  Graph rebuild(void Function(GraphBuilder g) block) {
    final builder = GraphBuilder()..addAll(this);
    block(builder);
    return builder.build();
  }

  /// Whether adding an edge from [from] to [to] would close a cycle (self-loops included).
  bool wouldCreateCycle(String from, String to) => _adjacency._hasPath(to, from);

  /// Whether the graph contains a cycle, self-loops included.
  bool hasCycles() {
    if (edges.any((edge) => edge.isSelfLoop)) return true;
    return findStronglyConnectedComponents().any((component) => component.length > 1);
  }

  /// Classifies a single edge. Classifies the whole graph to do so: prefer [classifyAllEdges]
  /// when you need more than one.
  EdgeType classifyEdge(GraphEdge edge) => classifyAllEdges()[edge] ?? EdgeType.cross;

  /// Classifies every edge in one O(V + E) depth-first pass. Edges between the same two nodes in
  /// the same direction share a type.
  Map<GraphEdge, EdgeType> classifyAllEdges() {
    final result = <GraphEdge, EdgeType>{};
    for (final edge in edges) {
      if (edge.isSelfLoop) result[edge] = EdgeType.selfLoop;
    }

    final discovery = <String, int>{};
    final finish = <String, int>{};
    final inPath = <String>{};
    final stack = <(String, Iterator<String>)>[];
    var time = 0;

    void classify(List<GraphEdge> pairEdges, EdgeType type) {
      for (final edge in pairEdges) {
        result[edge] = type;
      }
    }

    void enter(String nodeId) {
      discovery[nodeId] = ++time;
      inPath.add(nodeId);
      stack.add((nodeId, (_adjacency[nodeId] ?? const <String>{}).iterator));
    }

    for (final start in nodes.keys) {
      if (discovery.containsKey(start)) continue;
      enter(start);
      while (stack.isNotEmpty) {
        final (nodeId, neighbors) = stack.last;
        if (!neighbors.moveNext()) {
          inPath.remove(nodeId);
          finish[nodeId] = ++time;
          stack.removeLast();
          continue;
        }
        final neighbor = neighbors.current;
        final pairEdges = _edgesByPair[(nodeId, neighbor)];
        if (pairEdges == null || result.containsKey(pairEdges.first)) continue;

        if (inPath.contains(neighbor)) {
          classify(pairEdges, EdgeType.back);
        } else if (!discovery.containsKey(neighbor)) {
          classify(pairEdges, EdgeType.forward);
          enter(neighbor);
        } else {
          // Already finished: forward when discovered below the current node, otherwise cross
          final isDescendant = finish.containsKey(neighbor) && discovery[neighbor]! > discovery[nodeId]!;
          classify(pairEdges, isDescendant ? EdgeType.forward : EdgeType.cross);
        }
      }
    }

    for (final edge in edges) {
      result.putIfAbsent(edge, () => EdgeType.cross);
    }
    return result;
  }

  /// Finds the strongly connected components (Tarjan, iterative). A component with more than one
  /// node contains a cycle.
  List<Set<String>> findStronglyConnectedComponents() {
    final index = <String, int>{};
    final lowLink = <String, int>{};
    final onStack = <String>{};
    final stack = <String>[];
    final components = <Set<String>>[];
    final callStack = <(String, Iterator<String>)>[];
    var currentIndex = 0;

    void enter(String nodeId) {
      index[nodeId] = currentIndex;
      lowLink[nodeId] = currentIndex;
      currentIndex++;
      stack.add(nodeId);
      onStack.add(nodeId);
      callStack.add((nodeId, (_adjacency[nodeId] ?? const <String>{}).iterator));
    }

    for (final start in nodes.keys) {
      if (index.containsKey(start)) continue;
      enter(start);
      while (callStack.isNotEmpty) {
        final (nodeId, neighbors) = callStack.last;
        if (neighbors.moveNext()) {
          final neighbor = neighbors.current;
          if (!index.containsKey(neighbor)) {
            enter(neighbor);
          } else if (onStack.contains(neighbor)) {
            lowLink[nodeId] = math.min(lowLink[nodeId]!, index[neighbor]!);
          }
          continue;
        }

        callStack.removeLast();
        if (lowLink[nodeId] == index[nodeId]) {
          final component = <String>{};
          String member;
          do {
            member = stack.removeLast();
            onStack.remove(member);
            component.add(member);
          } while (member != nodeId);
          components.add(component);
        }
        if (callStack.isNotEmpty) {
          final parentId = callStack.last.$1;
          lowLink[parentId] = math.min(lowLink[parentId]!, lowLink[nodeId]!);
        }
      }
    }
    return components;
  }

  /// Node ids in topological order (Kahn). Nodes on a cycle, and nodes only reachable through
  /// one, are left out, so the result holds every node only for acyclic graphs.
  List<String> topologicalOrder() {
    final inDegree = <String, int>{for (final id in nodes.keys) id: 0};
    for (final targets in _adjacency.values) {
      for (final target in targets) {
        inDegree[target] = (inDegree[target] ?? 0) + 1;
      }
    }
    final queue = Queue<String>.of([
      for (final MapEntry(key: id, value: degree) in inDegree.entries)
        if (degree == 0) id,
    ]);
    final result = <String>[];
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      result.add(current);
      for (final neighbor in _adjacency[current] ?? const <String>{}) {
        final degree = inDegree[neighbor]! - 1;
        inDegree[neighbor] = degree;
        if (degree == 0) queue.addLast(neighbor);
      }
    }
    return result;
  }

  /// A copy whose edges carry their type in [types], which [classifyAllEdges] computed for them.
  Graph _withEdgeTypes(Map<GraphEdge, EdgeType> types) {
    final updatedEdges = <GraphEdge>{for (final edge in edges) edge.copyWith(type: types[edge])};
    return Graph._(nodes, updatedEdges, _adjacency, {for (final edge in updatedEdges) edge.id: edge});
  }

  void _requireEndpoints(GraphEdge edge) {
    for (final id in [edge.fromId, edge.toId]) {
      if (!nodes.containsKey(id)) {
        throw ArgumentError('Edge ${edge.fromId} -> ${edge.toId} references unknown node $id');
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Graph && other._hashCode == _hashCode && mapEquals(other.nodes, nodes) && setEquals(other.edges, edges);

  @override
  int get hashCode => _hashCode;

  @override
  String toString() => 'Graph(nodes: ${nodes.length}, edges: ${edges.length})';
}

/// Mutable builder for [Graph], the receiver of [Graph.build] and [Graph.rebuild]. Collect nodes
/// and edges, then [build] an immutable graph. The builder stays usable afterwards.
final class GraphBuilder {
  final Map<String, GraphNode> _nodes = {};
  final Set<GraphEdge> _edges = {};
  final Map<String, Set<String>> _adjacency = {};
  final Map<String, GraphEdge> _edgeMap = {};

  /// Adds [node] unless a node with the same id is present. Returns whether it was added.
  bool addNode(GraphNode node) {
    if (_nodes.containsKey(node.id)) return false;
    _nodes[node.id] = node;
    _adjacency[node.id] = {};
    return true;
  }

  /// Adds [edge] unless an endpoint is missing or its id is taken; the first edge with an id wins.
  /// Returns whether it was added.
  ///
  /// Throws an [ArgumentError] if the id already belongs to an edge between other nodes.
  bool addEdge(GraphEdge edge) {
    if (!_nodes.containsKey(edge.fromId) || !_nodes.containsKey(edge.toId)) return false;
    final existing = _edgeMap[edge.id];
    if (existing != null) {
      existing._requireSameEndpoints(edge);
      return false;
    }
    _edges.add(edge);
    _adjacency[edge.fromId]!.add(edge.toId);
    _edgeMap[edge.id] = edge;
    return true;
  }

  /// Adds a node with [id] and an optional fixed [size].
  void node(String id, {Size? size}) => addNode(GraphNode(id, size: size));

  /// Adds a node for every id in [ids].
  void nodes(Iterable<String> ids) {
    for (final id in ids) {
      addNode(GraphNode(id));
    }
  }

  /// Adds an edge from [from] to [to], unless its id is taken. See [addEdge].
  void edge(String from, String to, {String? fromAnchor, String? toAnchor, String? id}) =>
      addEdge(GraphEdge(from, to, fromAnchor: fromAnchor, toAnchor: toAnchor, id: id));

  /// Adds an edge for every `(from, to)` pair, skipping pairs that are already connected.
  void edges(Iterable<(String, String)> pairs) {
    for (final (from, to) in pairs) {
      addEdge(GraphEdge(from, to));
    }
  }

  /// Adds an edge for every `(from, to)` pair, creating missing nodes unless [createNodes] is
  /// `false`.
  void fromEdgeList(Iterable<(String, String)> pairs, {bool createNodes = true}) {
    for (final (from, to) in pairs) {
      if (createNodes) {
        addNode(GraphNode(from));
        addNode(GraphNode(to));
      }
      addEdge(GraphEdge(from, to));
    }
  }

  /// Whether an edge from [from] to [to] would close a cycle over what was added so far.
  bool wouldCreateCycle(String from, String to) => _adjacency._hasPath(to, from);

  /// Adds every node and edge of [graph], keeping nodes already present.
  void addAll(Graph graph) {
    graph.nodes.values.forEach(addNode);
    graph.edges.forEach(addEdge);
  }

  /// Freezes the collected nodes and edges into an immutable [Graph].
  Graph build() => Graph._(
    Map.of(_nodes),
    Set.of(_edges),
    {for (final MapEntry(key: id, value: targets) in _adjacency.entries) id: Set.of(targets)},
    Map.of(_edgeMap),
  );
}

extension on GraphEdge {
  void _requireSameEndpoints(GraphEdge other) {
    if (fromId != other.fromId || toId != other.toId) {
      throw ArgumentError('Edge id ${other.id} already connects $fromId -> $toId');
    }
  }
}

extension on Map<String, Set<String>> {
  /// Iterative reachability check.
  bool _hasPath(String from, String to) {
    final visited = <String>{};
    final pending = <String>[from];
    while (pending.isNotEmpty) {
      final nodeId = pending.removeLast();
      if (nodeId == to) return true;
      if (!visited.add(nodeId)) continue;
      pending.addAll(this[nodeId] ?? const <String>{});
    }
    return false;
  }
}
