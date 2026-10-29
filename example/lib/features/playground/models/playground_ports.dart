import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/port_side.dart';

/// Ports of the playground: one anchor per edge end, named by role (`out-0`, `in-1`, `back-out-0`…).
extension PlaygroundPorts on Graph {
  /// The graph with its own anchor for every edge end. Self-loops attach to the node boundary.
  Graph withPorts() {
    final types = classifyAllEdges();
    final used = <String, int>{};
    String next(String nodeId, String prefix) {
      final key = '$nodeId/$prefix';
      final index = used[key] ?? 0;
      used[key] = index + 1;
      return '$prefix-$index';
    }

    final sorted = edges.toList()..sort((a, b) => a.id.compareTo(b.id));
    return _withEdgesReplaced([
      for (final edge in sorted)
        if (edge.fromId == edge.toId)
          _unanchored(edge)
        else if (types[edge] == EdgeType.back)
          _anchored(edge, next(edge.fromId, 'back-out'), next(edge.toId, 'back-in'))
        else
          _anchored(edge, next(edge.fromId, 'out'), next(edge.toId, 'in')),
    ]);
  }

  /// The graph with every edge attached to the node boundaries.
  Graph withoutPorts() => _withEdgesReplaced([for (final edge in edges) _unanchored(edge)]);

  /// Anchor ids on node [nodeId] by side: outgoing ports face the flow direction, incoming ones the
  /// opposite side and back-edge ports a side of their own.
  Map<PortSide, List<String>> portsOf(String nodeId, {required bool vertical}) {
    final ids = <String>{
      for (final edge in edges) ...[
        if (edge.fromId == nodeId) ?edge.fromAnchor,
        if (edge.toId == nodeId) ?edge.toAnchor,
      ],
    }.toList()..sort(_comparePorts);
    final result = <PortSide, List<String>>{};
    for (final id in ids) {
      result.putIfAbsent(_sideOf(id, vertical: vertical), () => []).add(id);
    }
    return result;
  }

  int _comparePorts(String a, String b) {
    final byPrefix = _prefixOf(a).compareTo(_prefixOf(b));
    if (byPrefix != 0) return byPrefix;
    return _indexOf(a).compareTo(_indexOf(b));
  }

  String _prefixOf(String anchorId) {
    final dash = anchorId.lastIndexOf('-');
    if (dash < 0) return anchorId;
    return anchorId.substring(0, dash);
  }

  int _indexOf(String anchorId) => int.tryParse(anchorId.substring(anchorId.lastIndexOf('-') + 1)) ?? 0;

  PortSide _sideOf(String anchorId, {required bool vertical}) {
    if (anchorId.startsWith('back')) return vertical ? PortSide.left : PortSide.top;
    if (anchorId.startsWith('out')) return vertical ? PortSide.bottom : PortSide.right;
    return vertical ? PortSide.top : PortSide.left;
  }

  GraphEdge _anchored(GraphEdge edge, String fromAnchor, String toAnchor) =>
      GraphEdge(edge.fromId, edge.toId, type: edge.type, fromAnchor: fromAnchor, toAnchor: toAnchor, id: edge.id);

  GraphEdge _unanchored(GraphEdge edge) => GraphEdge(edge.fromId, edge.toId, type: edge.type, id: edge.id);

  Graph _withEdgesReplaced(List<GraphEdge> newEdges) => Graph.build((g) {
    nodes.values.forEach(g.addNode);
    newEdges.forEach(g.addEdge);
  });
}
