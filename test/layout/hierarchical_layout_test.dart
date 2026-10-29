import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

void main() {
  Graph graphOf(List<String> ids, List<(String, String)> pairs) => Graph.build(
    (g) => g
      ..nodes(ids)
      ..edges(pairs),
  );

  Graph run(
    Graph graph, {
    LayoutDirection direction = LayoutDirection.horizontal,
    Size canvas = const Size(800, 600),
  }) => GraphLayout.run(graph, LayoutConfig.hierarchical(direction: direction, canvasSize: canvas));

  test('a chain flows along the layout direction', () {
    final chain = graphOf(['A', 'B', 'C'], [('A', 'B'), ('B', 'C')]);

    final horizontal = run(chain);
    expect(horizontal.nodes['A']!.position.dx, lessThan(horizontal.nodes['B']!.position.dx));
    expect(horizontal.nodes['B']!.position.dx, lessThan(horizontal.nodes['C']!.position.dx));

    final vertical = run(chain, direction: LayoutDirection.vertical);
    expect(vertical.nodes['A']!.position.dy, lessThan(vertical.nodes['B']!.position.dy));
    expect(vertical.nodes['B']!.position.dy, lessThan(vertical.nodes['C']!.position.dy));
  });

  test('a diamond puts both middle nodes on one level', () {
    final result = run(graphOf(['A', 'B', 'C', 'D'], [('A', 'B'), ('A', 'C'), ('B', 'D'), ('C', 'D')]));
    final [a, b, c, d] = ['A', 'B', 'C', 'D'].map((id) => result.nodes[id]!.position).toList();

    expect(a.dx, lessThan(b.dx));
    expect(b.dx, closeTo(c.dx, 1));
    expect(b.dy, isNot(closeTo(c.dy, 1)));
    expect(d.dx, greaterThan(b.dx));
  });

  test('levels follow the longest path', () {
    final result = run(
      graphOf(
        ['a', 'b', 'c', 'd', 'e'],
        [('a', 'e'), ('a', 'b'), ('a', 'd'), ('b', 'c'), ('b', 'd'), ('b', 'e'), ('c', 'd'), ('d', 'e')],
      ),
    );
    final xs = ['a', 'b', 'c', 'd', 'e'].map((id) => result.nodes[id]!.position.dx).toList();

    for (var i = 0; i < xs.length - 1; i++) {
      expect(xs[i], lessThan(xs[i + 1]));
    }
    expect(result.edges, hasLength(8));
  });

  test('cycles are laid out and their back edges classified', () {
    final result = run(graphOf(['A', 'B', 'C'], [('A', 'B'), ('B', 'C'), ('C', 'A')]));

    expect(result.nodes, hasLength(3));
    expect(result.edges.map((e) => e.type), containsAll([EdgeType.forward, EdgeType.back]));
    expect(result.edges.every((e) => e.type != null), isTrue);
  });

  test('isolated nodes get their own level after the connected ones', () {
    final result = run(graphOf(['a', 'b', 'c', 'd', 'e'], [('a', 'b'), ('a', 'c'), ('b', 'c')]));
    final positions = result.nodes.map((id, node) => MapEntry(id, node.position));

    final maxConnected = [
      positions['a']!,
      positions['b']!,
      positions['c']!,
    ].map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    expect(positions['d']!.dx, greaterThan(maxConnected));
    expect(positions['d']!.dx, positions['e']!.dx);
    expect(positions.values.where((p) => p.dx == positions['a']!.dx), hasLength(1));
  });

  test('level spacing grows with the largest node', () {
    final graph = Graph.build(
      (g) => g
        ..node('small', size: const Size(50, 30))
        ..node('large', size: const Size(200, 100))
        ..node('medium', size: const Size(100, 60))
        ..edges([('small', 'large'), ('large', 'medium')]),
    );

    final result = run(graph);
    final small = result.nodes['small']!.position;
    final large = result.nodes['large']!.position;
    final medium = result.nodes['medium']!.position;

    expect(large.dx - small.dx, greaterThanOrEqualTo(260));
    expect(large.dx, lessThan(medium.dx));
  });

  test('node boxes of one level never overlap', () {
    final graph = Graph.build((g) {
      g.node('root', size: const Size(80, 40));
      for (var i = 0; i < 6; i++) {
        g
          ..node('child$i', size: Size(60 + i * 10, 30 + i * 8))
          ..edge('root', 'child$i');
      }
    });

    final result = run(graph);
    final boxes = [
      for (var i = 0; i < 6; i++)
        Rect.fromCenter(
          center: result.nodes['child$i']!.position,
          width: result.nodes['child$i']!.size!.width,
          height: result.nodes['child$i']!.size!.height,
        ),
    ];
    for (var i = 0; i < boxes.length; i++) {
      for (var j = i + 1; j < boxes.length; j++) {
        expect(boxes[i].overlaps(boxes[j]), isFalse, reason: 'child$i overlaps child$j');
      }
    }
  });

  test('the layout is centered in a measured canvas', () {
    final result = run(graphOf(['A', 'B'], [('A', 'B')]), canvas: const Size(1000, 500));
    final a = result.nodes['A']!.position;
    final b = result.nodes['B']!.position;

    expect((a.dx + b.dx) / 2, closeTo(500, 1));
    expect((a.dy + b.dy) / 2, closeTo(250, 1));
  });

  test('a chain too deep for recursion is laid out in order', () {
    const length = 10000;
    final graph = Graph.build((g) {
      g.nodes([for (var i = 0; i < length; i++) 'n$i']);
      for (var i = 0; i < length - 1; i++) {
        g.edge('n$i', 'n${i + 1}');
      }
    });

    final result = run(graph, canvas: Size.zero);
    for (var i = 0; i < length - 1; i++) {
      expect(result.nodes['n$i']!.position.dx, lessThan(result.nodes['n${i + 1}']!.position.dx));
    }
    expect(run(graph.withEdge(const GraphEdge('n${length - 1}', 'n0'))).nodes, hasLength(length));
  });

  test('a parallel edge keeps its id and moves no node', () {
    final single = graphOf(['A', 'B', 'C', 'D'], [('A', 'B'), ('A', 'C'), ('B', 'D'), ('A', 'D')]);
    final doubled = single.rebuild((g) => g.edge('A', 'D', id: 'again'));

    final result = run(doubled);
    expect(result.nodes, run(single).nodes);
    expect(result.edges.any((e) => e.id == 'again'), isTrue);
  });

  test('is deterministic and leaves its input alone', () {
    final graph = graphOf(['A', 'B', 'C', 'D'], [('A', 'C'), ('B', 'C'), ('C', 'D'), ('A', 'D')]);

    expect(run(graph), run(graph));
    expect(graph.nodes.values.every((n) => n.position == Offset.zero), isTrue);
  });

  test('an empty graph stays empty', () {
    expect(run(Graph.empty()).nodes, isEmpty);
  });

  test('polls checkCancelled and stops when it throws', () {
    final chain = graphOf(['A', 'B', 'C'], [('A', 'B'), ('B', 'C')]);
    var polls = 0;
    GraphLayout.run(chain, const LayoutConfig.hierarchical(), checkCancelled: () => polls++);
    expect(polls, greaterThan(0));

    expect(
      () => GraphLayout.run(
        chain,
        const LayoutConfig.hierarchical(),
        checkCancelled: () => throw const LayoutCancelledException(),
      ),
      throwsA(isA<LayoutCancelledException>()),
    );
  });

  test('back edges and self loops are set aside before levels are assigned', () {
    final graph = Graph.build(
      (g) => g
        ..nodes(['A', 'B', 'C'])
        ..edges([('A', 'B'), ('B', 'C'), ('C', 'A'), ('B', 'B')]),
    );
    final result = run(graph);
    double x(String id) => result.nodes[id]!.position.dx;

    expect(x('A'), lessThan(x('B')));
    expect(x('B'), lessThan(x('C')));
    expect(result.edge('C->A')!.type, EdgeType.back);
    expect(result.edge('B->B')!.type, EdgeType.selfLoop);
    expect(result.edge('A->B')!.type, EdgeType.forward);
    expect(result.wouldCreateCycle('C', 'A'), isTrue);
  });
}
