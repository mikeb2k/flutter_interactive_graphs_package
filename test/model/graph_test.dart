import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

void main() {
  Graph chain() => Graph.build(
    (g) => g
      ..nodes(['A', 'B', 'C'])
      ..edges([('A', 'B'), ('B', 'C')]),
  );

  group('cycles and classification', () {
    test('hasCycles detects a simple cycle, a self loop and accepts a DAG', () {
      final cycle = chain().withEdge(const GraphEdge('C', 'A'));
      final selfLoop = Graph.build(
        (g) => g
          ..nodes(['A'])
          ..edge('A', 'A'),
      );

      expect(cycle.hasCycles(), isTrue);
      expect(selfLoop.hasCycles(), isTrue);
      expect(chain().hasCycles(), isFalse);
    });

    test('classifies forward, back and self-loop edges', () {
      final graph = Graph.build(
        (g) => g
          ..nodes(['A', 'B'])
          ..edges([('A', 'B'), ('B', 'A'), ('A', 'A')]),
      );

      final types = graph.classifyAllEdges();
      expect(types[const GraphEdge('A', 'B')], EdgeType.forward);
      expect(types[const GraphEdge('B', 'A')], EdgeType.back);
      expect(types[const GraphEdge('A', 'A')], EdgeType.selfLoop);
      expect(graph.classifyEdge(const GraphEdge('A', 'B')), EdgeType.forward);
    });

    test('a shortcut to a finished descendant is forward, a sibling link is cross', () {
      final graph = Graph.build(
        (g) => g
          ..nodes(['A', 'B', 'C', 'D'])
          ..edges([('A', 'B'), ('B', 'C'), ('A', 'C'), ('A', 'D'), ('D', 'B')]),
      );

      final types = graph.classifyAllEdges();
      expect(types[const GraphEdge('A', 'C')], EdgeType.forward);
      expect(types[const GraphEdge('D', 'B')], EdgeType.cross);
    });

    test('wouldCreateCycle only reports edges that close a loop', () {
      final graph = chain().withNode(const GraphNode('D'));

      expect(graph.wouldCreateCycle('C', 'A'), isTrue);
      expect(graph.wouldCreateCycle('A', 'A'), isTrue);
      expect(graph.wouldCreateCycle('A', 'C'), isFalse);
      expect(graph.wouldCreateCycle('D', 'A'), isFalse);

      final cyclic = graph.withEdge(const GraphEdge('C', 'A'));
      expect(cyclic.wouldCreateCycle('C', 'B'), isTrue);
      expect(cyclic.wouldCreateCycle('C', 'D'), isFalse);
    });

    test('traversals handle a chain too deep for recursion', () {
      const length = 50000;
      final graph = Graph.build((g) {
        g.nodes([for (var i = 0; i < length; i++) 'n$i']);
        for (var i = 0; i < length - 1; i++) {
          g.edge('n$i', 'n${i + 1}');
        }
      });

      expect(graph.hasCycles(), isFalse);
      expect(graph.wouldCreateCycle('n${length - 1}', 'n0'), isTrue);
      expect(graph.wouldCreateCycle('n0', 'n${length - 1}'), isFalse);
      expect(graph.findStronglyConnectedComponents(), hasLength(length));

      final ring = graph.withEdge(const GraphEdge('n${length - 1}', 'n0'));
      expect(ring.hasCycles(), isTrue);
      expect(ring.findStronglyConnectedComponents().single, hasLength(length));
    });

    test('parallel edges share their classification', () {
      final graph = Graph.build(
        (g) => g
          ..nodes(['A', 'B', 'C'])
          ..edge('A', 'B')
          ..edge('A', 'B', id: 'again')
          ..edge('B', 'A')
          ..edge('B', 'A', id: 'back again')
          ..edge('B', 'C'),
      );

      final types = graph.classifyAllEdges();
      expect(types, hasLength(5));
      expect(types[const GraphEdge('A', 'B', id: 'again')], EdgeType.forward);
      expect(types[const GraphEdge('B', 'A')], EdgeType.back);
      expect(types[const GraphEdge('B', 'A', id: 'back again')], EdgeType.back);

      final acyclic = graph.withoutEdge('B->A').withoutEdge('back again');
      expect(acyclic.topologicalOrder(), ['A', 'B', 'C']);
      expect(graph.hasParallelEdges, isTrue);
      expect(acyclic.withoutEdge('again').hasParallelEdges, isFalse);
    });

    test('topological order leaves out the nodes on a cycle', () {
      final graph = chain().withNode(const GraphNode('D')).withEdge(const GraphEdge('C', 'B'));

      expect(graph.topologicalOrder(), ['A', 'D']);
    });

    test('withClassifiedEdges stores the type on every edge', () {
      final graph = Graph.withClassifiedEdges(
        [const GraphNode('A'), const GraphNode('B')],
        [const GraphEdge('A', 'B'), const GraphEdge('B', 'A')],
      );

      expect(graph.edge('A->B')?.type, EdgeType.forward);
      expect(graph.edge('B->A')?.type, EdgeType.back);
    });
  });

  group('immutability', () {
    test('graphs with the same content are equal', () {
      expect(chain(), chain());
      expect(chain().hashCode, chain().hashCode);
    });

    test('changes return new graphs and leave the original alone', () {
      final original = chain();
      final withNode = original.withNode(const GraphNode('D'));
      final withEdge = original.withEdge(const GraphEdge('A', 'C'));

      expect(withNode, isNot(original));
      expect(withEdge, isNot(original));
      expect(original.nodes, hasLength(3));
      expect(original.edges, hasLength(2));
      expect(withEdge.wouldCreateCycle('C', 'A'), isTrue);
    });

    test('node positions differing makes graphs unequal', () {
      final flat = Graph.build((g) => g.addNode(const GraphNode('A')));
      final moved = flat.withNode(const GraphNode('A', position: Offset(10, 10)));

      expect(moved, isNot(flat));
      expect(flat.nodes['A']!.position, Offset.zero);
    });

    test('withNode replaces an existing node and keeps its edges', () {
      final original = chain();
      final resized = original.withNode(const GraphNode('B', size: Size(40, 20)));

      expect(resized.nodes, hasLength(3));
      expect(resized.nodes['B']!.size, const Size(40, 20));
      expect(resized.edges, original.edges);
      expect(resized.topologicalOrder(), ['A', 'B', 'C']);
    });

    test('a change that changes nothing returns the same instance', () {
      final original = chain();

      expect(original.withNode(original.nodes['A']!), same(original));
      expect(original.withEdge(original.edges.first), same(original));
      expect(original.withoutNode('nope'), same(original));
      expect(original.withoutEdge('A->C'), same(original));
      expect(original.withMeasuredSizes(const {}), same(original));
      expect(original.withNodes(const []), same(original));
    });

    test('withEdge rejects an edge into a node that is not in the graph', () {
      expect(() => chain().withEdge(const GraphEdge('A', 'Z')), throwsArgumentError);
      expect(() => chain().withEdge(const GraphEdge('Z', 'A')), throwsArgumentError);
    });

    test('withEdge keeps the edge already holding the id', () {
      final original = chain();
      final again = original.withEdge(const GraphEdge('A', 'B', fromAnchor: 'right', toAnchor: 'left'));

      expect(again, same(original));
      expect(again.edges, {const GraphEdge('A', 'B'), const GraphEdge('B', 'C')});
    });

    test('withEdges skips the ids that are already taken', () {
      final extended = chain().withEdges(const [
        GraphEdge('A', 'B', fromAnchor: 'right'),
        GraphEdge('A', 'C'),
        GraphEdge('A', 'C', toAnchor: 'top'),
      ]);

      expect(extended.edges, {const GraphEdge('A', 'B'), const GraphEdge('B', 'C'), const GraphEdge('A', 'C')});
      expect(extended.withEdges(const [GraphEdge('A', 'B'), GraphEdge('A', 'C')]), same(extended));
    });

    test('the builder takes one edge per id and the other direction is its own edge', () {
      final builder = GraphBuilder()
        ..addNode(const GraphNode('A'))
        ..addNode(const GraphNode('B'));

      expect(builder.addEdge(const GraphEdge('A', 'B')), isTrue);
      expect(builder.addEdge(const GraphEdge('A', 'B', fromAnchor: 'right')), isFalse);
      expect(builder.addEdge(const GraphEdge('B', 'A')), isTrue);
      expect(builder.build().edges, {const GraphEdge('A', 'B'), const GraphEdge('B', 'A')});
    });

    test('explicit ids connect the same pair several times', () {
      final single = chain().withEdge(const GraphEdge('A', 'B', id: 'second'));
      final batch = chain().withEdges(const [GraphEdge('A', 'B', id: 'second'), GraphEdge('A', 'B', id: 'second')]);

      expect(single.edgesBetween('A', 'B').map((e) => e.id), ['A->B', 'second']);
      expect(single.edgesBetween('B', 'A'), isEmpty);
      expect(single, batch);
    });

    test('an id already connecting other nodes is rejected', () {
      const stale = GraphEdge('A', 'C', id: 'A->B');

      expect(
        () => chain().withEdge(stale),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Edge id A->B already connects A -> B')),
      );
      expect(() => chain().withEdges(const [stale]), throwsArgumentError);
      expect(() => chain().rebuild((g) => g.addEdge(stale)), throwsArgumentError);
      expect(
        () => chain().withEdges(const [GraphEdge('A', 'C', id: 'x'), GraphEdge('B', 'C', id: 'x')]),
        throwsArgumentError,
      );
    });

    test('withoutNode drops the edges that touch it', () {
      final trimmed = chain().withoutNode('B');

      expect(trimmed.nodes.keys, ['A', 'C']);
      expect(trimmed.edges, isEmpty);
    });

    test('withoutEdge drops only that edge, matched by id', () {
      final original = chain().rebuild((g) => g.edge('A', 'B', id: 'second'));

      final trimmed = original.withoutEdge('second');
      expect(trimmed, chain());
      expect(trimmed.wouldCreateCycle('B', 'A'), isTrue);
      expect(trimmed.withoutEdge('A->B').wouldCreateCycle('B', 'A'), isFalse);

      final untouched = chain();
      expect(untouched.withoutEdge('B->A'), same(untouched), reason: 'the default id is directed');
    });

    test('rebuild starts from the current content', () {
      final original = chain();
      final extended = original.rebuild(
        (g) => g
          ..nodes(['D'])
          ..edge('C', 'D'),
      );

      expect(extended.nodes, hasLength(4));
      expect(extended.edges, hasLength(3));
      expect(original, chain());
      expect(extended.topologicalOrder(), ['A', 'B', 'C', 'D']);
    });

    test('a builder reused after build does not reach into the graph it made', () {
      final builder = GraphBuilder()..nodes(['A', 'B']);
      final first = builder.build();
      builder
        ..nodes(['C'])
        ..edge('A', 'C');

      expect(first.nodes, hasLength(2));
      expect(first.edges, isEmpty);
      expect(builder.build().nodes, hasLength(3));
    });

    test('withMeasuredSizes replaces sizes where given and keeps the rest', () {
      final measured = chain().withMeasuredSizes(const {'A': Size(10, 20)});

      expect(measured.nodes['A']!.size, const Size(10, 20));
      expect(measured.nodes['B']!.size, isNull);
      expect(measured.withMeasuredSizes(const {'A': Size(10, 20)}), same(measured));
    });

    test('the exposed collections cannot be modified', () {
      final graph = chain();

      expect(() => graph.nodes['X'] = const GraphNode('X'), throwsUnsupportedError);
      expect(() => graph.edges.add(const GraphEdge('A', 'C')), throwsUnsupportedError);
    });
  });

  group('builder helpers', () {
    test('edge carries anchors and id', () {
      final graph = Graph.build(
        (g) => g
          ..nodes(['A', 'B'])
          ..edge('A', 'B', fromAnchor: 'right', toAnchor: 'left'),
      );

      final edge = graph.edges.single;
      expect(edge.fromAnchor, 'right');
      expect(edge.toAnchor, 'left');
      expect(edge.id, 'A->B');
    });

    test('edges into unknown nodes are skipped by the builder', () {
      final graph = Graph.build(
        (g) => g
          ..nodes(['A'])
          ..edge('A', 'B'),
      );

      expect(graph.edges, isEmpty);
    });

    test('fromEdgeList creates the nodes it needs, unless told not to', () {
      final created = Graph.build((g) => g.fromEdgeList([('A', 'B'), ('B', 'C')]));
      final bare = Graph.build((g) => g.fromEdgeList([('A', 'B')], createNodes: false));

      expect(created.nodes.keys, ['A', 'B', 'C']);
      expect(created.edges, hasLength(2));
      expect(bare.nodes, isEmpty);
      expect(bare.edges, isEmpty);
    });

    test('wouldCreateCycle answers on what the builder holds so far', () {
      final builder = GraphBuilder()
        ..nodes(['A', 'B', 'C'])
        ..edge('A', 'B');

      expect(builder.wouldCreateCycle('B', 'A'), isTrue);
      expect(builder.wouldCreateCycle('C', 'A'), isFalse);
    });
  });

  group('nodes and edges', () {
    test('edge default id is directed and copyWith keeps it', () {
      const edge = GraphEdge('A', 'B');

      expect(edge.id, 'A->B');
      expect(edge.copyWith(type: EdgeType.back).id, 'A->B');
      expect(edge.copyWith(type: EdgeType.back), isNot(edge));
      expect(edge.isSelfLoop, isFalse);
      expect(const GraphEdge('A', 'A').isSelfLoop, isTrue);
    });

    test('withAnchors replaces both anchors, null included, and keeps the id', () {
      const edge = GraphEdge('A', 'B', fromAnchor: 'right', toAnchor: 'left', id: 'e');

      expect(edge.withAnchors(), const GraphEdge('A', 'B', id: 'e'));
      expect(edge.withAnchors(toAnchor: 'top').fromAnchor, isNull);
      expect(edge.withAnchors(toAnchor: 'top').toAnchor, 'top');
    });

    test('node copyWith and withSize', () {
      const node = GraphNode('A', size: Size(10, 10));

      expect(node.copyWith(position: const Offset(1, 2)).position, const Offset(1, 2));
      expect(node.withSize(null).size, isNull);
      expect(node.copyWith(position: const Offset(1, 2)).size, const Size(10, 10));
    });
  });
}
