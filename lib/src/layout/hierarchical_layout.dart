import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:interactive_graphs/src/layout/layout_config.dart';
import 'package:interactive_graphs/src/model/graph.dart';
import 'package:interactive_graphs/src/model/graph_edge.dart';

/// Sugiyama-style layered layout.
///
/// 1. Cycle removal: a depth-first pass sets back edges aside.
/// 2. Level assignment by longest path. Isolated nodes get a level of their own after the rest.
/// 3. Crossing reduction with the barycenter heuristic (alternating down and up sweeps).
/// 4. Coordinates: levels [HierarchicalLayoutConfig.levelSpacing] apart, nodes of a level
///    [HierarchicalLayoutConfig.nodeSpacing] apart, both grown to fit the largest node. Edges that
///    skip levels get a gap in the levels they cross.
///
/// References: Sugiyama et al. (1981), "Methods for Visual Understanding of Hierarchical System
/// Structures"; Di Battista et al. (1998), "Graph Drawing".
abstract final class HierarchicalLayout {
  /// Clearance kept between levels on top of the largest node along the flow direction.
  static const double levelClearance = 60;

  /// Clearance kept between nodes of a level on top of the largest node across the flow.
  static const double nodeClearance = 40;

  static const int _sweeps = 10;

  /// Lays [graph] out. Positions are node centers; the result has every edge classified.
  static Graph run(Graph graph, HierarchicalLayoutConfig config) {
    final acyclicEdges = graph.hasCycles() ? _withoutBackEdges(graph) : graph.edges.toList();

    final parents = <String, Set<String>>{};
    final children = <String, Set<String>>{};
    for (final edge in acyclicEdges) {
      parents.putIfAbsent(edge.toId, () => <String>{}).add(edge.fromId);
      children.putIfAbsent(edge.fromId, () => <String>{}).add(edge.toId);
    }

    final levels = _longestPathLevels(graph, parents, children);
    final nodesByLevel = <int, List<String>>{};
    for (final MapEntry(key: id, value: level) in levels.entries) {
      nodesByLevel.putIfAbsent(level, () => []).add(id);
    }
    final maxLevel = nodesByLevel.keys.fold(0, math.max);

    final ordered = _minimizeCrossings(nodesByLevel, maxLevel, parents, children);
    final withGaps = _addBypassGaps(graph, ordered, levels);

    final indexInLevel = <String, int>{};
    for (final entries in withGaps.values) {
      for (var i = 0; i < entries.length; i++) {
        if (entries[i] case final _NodeEntry entry) indexInLevel[entry.id] = i;
      }
    }

    final nodeSize = config.nodeSize;
    var maxWidth = nodeSize;
    var maxHeight = nodeSize;
    if (graph.nodes.isNotEmpty) {
      maxWidth = graph.nodes.values.map((n) => n.size?.width ?? nodeSize).reduce(math.max);
      maxHeight = graph.nodes.values.map((n) => n.size?.height ?? nodeSize).reduce(math.max);
    }
    final horizontal = config.direction == LayoutDirection.horizontal;
    final levelSpacing = math.max(config.levelSpacing, (horizontal ? maxWidth : maxHeight) + levelClearance);
    final nodeSpacing = math.max(config.nodeSpacing, (horizontal ? maxHeight : maxWidth) + nodeClearance);
    final canvasAlong = horizontal ? config.canvasSize.width : config.canvasSize.height;
    final canvasAcross = horizontal ? config.canvasSize.height : config.canvasSize.width;
    final alongOffset = canvasAlong > 0 ? (canvasAlong - levelSpacing * maxLevel) / 2 : 0.0;
    final acrossOffset = canvasAcross > 0 ? canvasAcross / 2 : 0.0;

    final positioned = [
      for (final MapEntry(key: id, value: node) in graph.nodes.entries)
        node.copyWith(
          position: _position(
            along: levelSpacing * (levels[id] ?? 0) + alongOffset,
            across:
                nodeSpacing * (indexInLevel[id] ?? 0) -
                nodeSpacing * (withGaps[levels[id]]?.length ?? 0) / 2 +
                nodeSpacing / 2 +
                acrossOffset,
            horizontal: horizontal,
          ),
        ),
    ];
    return Graph.withClassifiedEdges(positioned, graph.edges);
  }

  static Offset _position({required double along, required double across, required bool horizontal}) =>
      horizontal ? Offset(along, across) : Offset(across, along);

  /// Longest-path levels over the acyclic edges, isolated nodes on a level after all others.
  static Map<String, int> _longestPathLevels(
    Graph graph,
    Map<String, Set<String>> parents,
    Map<String, Set<String>> children,
  ) {
    final levels = <String, int>{};
    final pendingParents = <String, int>{};
    final ready = Queue<String>();
    for (final id in graph.nodes.keys) {
      final parentCount = parents[id]?.length ?? 0;
      levels[id] = 0;
      pendingParents[id] = parentCount;
      if (parentCount == 0) ready.addLast(id);
    }
    while (ready.isNotEmpty) {
      final id = ready.removeFirst();
      final childLevel = levels[id]! + 1;
      for (final child in children[id] ?? const <String>{}) {
        levels[child] = math.max(levels[child]!, childLevel);
        final pending = pendingParents[child]! - 1;
        pendingParents[child] = pending;
        if (pending == 0) ready.addLast(child);
      }
    }

    final maxConnected = levels.values.fold(0, math.max);
    for (final id in graph.nodes.keys) {
      final connected = (parents[id]?.isNotEmpty ?? false) || (children[id]?.isNotEmpty ?? false);
      if (!connected) levels[id] = maxConnected + 1;
    }
    return levels;
  }

  /// Barycenter crossing reduction, stopping early once two rounds change nothing.
  static Map<int, List<String>> _minimizeCrossings(
    Map<int, List<String>> nodesByLevel,
    int maxLevel,
    Map<String, Set<String>> parents,
    Map<String, Set<String>> children,
  ) {
    final result = {for (final entry in nodesByLevel.entries) entry.key: List.of(entry.value)};
    var unchangedRounds = 0;

    for (var round = 0; round < _sweeps; round++) {
      final previous = {for (final entry in result.entries) entry.key: entry.value};

      for (var level = 1; level <= maxLevel; level++) {
        final current = result[level];
        final above = result[level - 1];
        if (current == null || above == null) continue;
        result[level] = _sortedByBarycenter(current, parents, _indexById(above));
      }
      for (var level = maxLevel - 1; level >= 0; level--) {
        final current = result[level];
        final below = result[level + 1];
        if (current == null || below == null) continue;
        result[level] = _sortedByBarycenter(current, children, _indexById(below));
      }

      final unchanged =
          result.length == previous.length && result.keys.every((k) => listEquals(result[k], previous[k]));
      if (unchanged) {
        if (++unchangedRounds >= 2) return result;
      } else {
        unchangedRounds = 0;
      }
    }
    return result;
  }

  static Map<String, int> _indexById(List<String> ids) => {for (var i = 0; i < ids.length; i++) ids[i]: i};

  /// Stable sort of [ids] by the mean position of their neighbors in the adjacent level. Nodes
  /// without neighbors there keep their relative order at the end.
  static List<String> _sortedByBarycenter(
    List<String> ids,
    Map<String, Set<String>> neighbors,
    Map<String, int> adjacentIndex,
  ) {
    final keyed = <(int, double, String)>[];
    for (var i = 0; i < ids.length; i++) {
      final positions = [
        for (final neighbor in neighbors[ids[i]] ?? const <String>{}) ?adjacentIndex[neighbor],
      ];
      final barycenter = positions.isEmpty
          ? double.maxFinite
          : positions.fold(0, (sum, p) => sum + p) / positions.length;
      keyed.add((i, barycenter, ids[i]));
    }
    keyed.sort((a, b) {
      final byCenter = a.$2.compareTo(b.$2);
      return byCenter != 0 ? byCenter : a.$1.compareTo(b.$1);
    });
    return [for (final entry in keyed) entry.$3];
  }

  /// Inserts a gap in every level an edge skips, so it doesn't run through the middle node.
  static Map<int, List<_LevelEntry>> _addBypassGaps(
    Graph graph,
    Map<int, List<String>> nodesByLevel,
    Map<String, int> levels,
  ) {
    final result = <int, List<_LevelEntry>>{
      for (final MapEntry(key: level, value: ids) in nodesByLevel.entries)
        level: [for (final id in ids) _NodeEntry(id)],
    };

    final seenPairs = <(String, String)>{};
    for (final edge in graph.edges) {
      if (!seenPairs.add((edge.fromId, edge.toId))) continue;
      final fromLevel = levels[edge.fromId] ?? 0;
      final toLevel = levels[edge.toId] ?? 0;
      if (toLevel - fromLevel <= 1) continue;

      for (var level = fromLevel + 1; level < toLevel; level++) {
        final entries = result[level];
        if (entries == null) continue;
        if (entries.length == 1) {
          result[level] = [const _SpacerEntry(), entries.first];
        } else {
          final mid = entries.length ~/ 2;
          result[level] = [...entries.take(mid), const _SpacerEntry(), ...entries.skip(mid)];
        }
      }
    }
    return result;
  }

  /// Edges that remain after a depth-first pass sets the back edges (and self-loops) aside.
  static List<GraphEdge> _withoutBackEdges(Graph graph) {
    final kept = <GraphEdge>[];
    final visited = <String>{};
    final inPath = <String>{};
    final classified = <GraphEdge>{};
    final outgoing = <String, List<GraphEdge>>{};
    for (final edge in graph.edges) {
      outgoing.putIfAbsent(edge.fromId, () => []).add(edge);
    }
    final stack = <(String, Iterator<GraphEdge>)>[];

    void enter(String id) {
      visited.add(id);
      inPath.add(id);
      stack.add((id, (outgoing[id] ?? const <GraphEdge>[]).iterator));
    }

    for (final start in graph.nodes.keys) {
      if (visited.contains(start)) continue;
      enter(start);
      while (stack.isNotEmpty) {
        final (id, edges) = stack.last;
        if (!edges.moveNext()) {
          inPath.remove(id);
          stack.removeLast();
          continue;
        }
        final edge = edges.current;
        if (!classified.add(edge)) continue;
        if (edge.isSelfLoop || inPath.contains(edge.toId)) continue;
        kept.add(edge);
        if (!visited.contains(edge.toId)) enter(edge.toId);
      }
    }
    for (final edge in graph.edges) {
      if (!classified.contains(edge)) kept.add(edge);
    }
    return kept;
  }
}

sealed class _LevelEntry {
  const _LevelEntry();
}

final class _NodeEntry extends _LevelEntry {
  const _NodeEntry(this.id);

  final String id;
}

final class _SpacerEntry extends _LevelEntry {
  const _SpacerEntry();
}
