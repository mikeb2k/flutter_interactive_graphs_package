import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

void main() {
  const box = Size(40, 20);
  const padding = EdgeEndpoints.padding;

  test('a straight edge starts and ends on the node boxes plus padding', () {
    final (start, end) = EdgeEndpoints.resolve(
      edge: const GraphEdge('A', 'B'),
      fromCenter: Offset.zero,
      fromSize: box,
      toCenter: const Offset(100, 0),
      toSize: box,
    );

    expect(start, const Offset(20 + padding, 0));
    expect(end, const Offset(80 - padding, 0));
  });

  test('vertical neighbours meet the top and bottom sides', () {
    final (start, end) = EdgeEndpoints.resolve(
      edge: const GraphEdge('A', 'B'),
      fromCenter: Offset.zero,
      fromSize: box,
      toCenter: const Offset(0, 100),
      toSize: box,
    );

    expect(start, const Offset(0, 10 + padding));
    expect(end, const Offset(0, 90 - padding));
  });

  test('anchors replace the boundary point on their side only', () {
    final (start, end) = EdgeEndpoints.resolve(
      edge: const GraphEdge('A', 'B', fromAnchor: 'right'),
      fromCenter: Offset.zero,
      fromSize: box,
      toCenter: const Offset(100, 0),
      toSize: box,
      fromAnchorOffset: const Offset(40, 10),
    );

    expect(start, const Offset(20, 0), reason: 'anchor offsets are relative to the top-left corner');
    expect(end, const Offset(80 - padding, 0));
  });

  test('back edges leave at the curve tangent angle', () {
    final (start, _) = EdgeEndpoints.resolve(
      edge: const GraphEdge('A', 'B', type: EdgeType.back),
      fromCenter: Offset.zero,
      fromSize: const Size(40, 40),
      toCenter: const Offset(100, 0),
      toSize: const Size(40, 40),
    );

    expect(start.dy, greaterThan(0), reason: 'rotated towards the side the curve bends to');
  });

  test('self loops start and end on the top side, wider with a bend', () {
    final (start, end) = EdgeEndpoints.resolve(
      edge: const GraphEdge('A', 'A'),
      fromCenter: Offset.zero,
      fromSize: box,
      toCenter: Offset.zero,
      toSize: box,
    );
    final (wideStart, _) = EdgeEndpoints.resolve(
      edge: const GraphEdge('A', 'A'),
      bend: const EdgeBend(0.5),
      fromCenter: Offset.zero,
      fromSize: box,
      toCenter: Offset.zero,
      toSize: box,
    );

    expect(start, const Offset(-6, -10));
    expect(end, const Offset(6, -10));
    expect(wideStart.dx, lessThan(start.dx));
  });

  group('parallel edges', () {
    test('single edges get no bend, twins fan out symmetrically', () {
      final bends = ParallelEdges.bends(const [
        GraphEdge('A', 'B'),
        GraphEdge('A', 'B', id: 'A->B#2'),
        GraphEdge('B', 'C'),
      ]);

      expect(bends.keys, unorderedEquals(['A->B', 'A->B#2']));
      expect(bends['A->B']!.amount, closeTo(-bends['A->B#2']!.amount, 1e-9));
    });

    test('back-edge twins stay on the side of their usual curve', () {
      final bends = ParallelEdges.bends(const [
        GraphEdge('B', 'A', type: EdgeType.back),
        GraphEdge('B', 'A', type: EdgeType.back, id: 'again'),
      ]);

      expect(bends.values.every((b) => b.amount > 0), isTrue);
    });

    test('nested self loops grow', () {
      final bends = ParallelEdges.bends(const [GraphEdge('A', 'A'), GraphEdge('A', 'A', id: 'second')]);

      expect(bends['A->A']!.amount, 0);
      expect(bends['second']!.amount, greaterThan(0));
    });
  });

  group('edge style', () {
    test('styled dashes back edges and self loops', () {
      const base = Color(0xFF000000);
      const back = Color(0xFFFF0000);

      final forward = EdgeStyle.styled(
        const GraphEdge('A', 'B', type: EdgeType.forward),
        baseColor: base,
        backEdgeColor: back,
      );
      final backEdge = EdgeStyle.styled(
        const GraphEdge('B', 'A', type: EdgeType.back),
        baseColor: base,
        backEdgeColor: back,
      );
      final loop = EdgeStyle.styled(
        const GraphEdge('A', 'A', type: EdgeType.selfLoop),
        baseColor: base,
        backEdgeColor: back,
      );

      expect(forward.dashed, isFalse);
      expect(backEdge.dashed, isTrue);
      expect(backEdge.color.a, closeTo(0.7, 0.01));
      expect(loop.color, back);
      expect(loop.dashed, isTrue);
    });

    test('auto shape curves back edges and keeps forward edges straight', () {
      const style = EdgeStyle();

      expect(
        style.createPath(const GraphEdge('A', 'B', type: EdgeType.forward), null, Offset.zero, const Offset(100, 0)),
        isA<StraightEdgePath>(),
      );
      expect(
        style.createPath(const GraphEdge('B', 'A', type: EdgeType.back), null, Offset.zero, const Offset(100, 0)),
        isA<CurvedEdgePath>(),
      );
      expect(
        style.createPath(const GraphEdge('A', 'A'), null, Offset.zero, const Offset(10, 0)),
        isA<SelfLoopEdgePath>(),
      );
      expect(
        style.createPath(const GraphEdge('A', 'B'), 0.15, Offset.zero, const Offset(100, 0)),
        isA<CurvedEdgePath>(),
      );
      expect(
        const EdgeStyle(shape: EdgeShape.rightAngle).createPath(
          const GraphEdge('A', 'B', fromAnchor: 'bottom', toAnchor: 'top'),
          null,
          Offset.zero,
          const Offset(100, 100),
        ),
        isA<RightAngleEdgePath>().having((p) => p.waypoints.first, 'first corner', const Offset(0, 50)),
      );
      expect(EdgeShape.orthogonal.fansOut, isFalse);
    });
  });
}
