import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

void main() {
  const from = Offset(0, 0);
  const to = Offset(100, 0);
  const edge = GraphEdge('A', 'B');
  const back = GraphEdge('A', 'B', type: EdgeType.back);

  group('createPath', () {
    test('auto is straight, curved for back edges and for a bend', () {
      const style = EdgeStyle();
      expect(style.createPath(edge, null, from, to), isA<StraightEdgePath>());
      expect(style.createPath(back, null, from, to), isA<CurvedEdgePath>());
      expect(style.createPath(edge, 0.15, from, to), isA<CurvedEdgePath>());
      expect(style.createPath(edge, 0, from, to), isA<StraightEdgePath>());
    });

    test('straight only curves for a bend, curved always curves', () {
      expect(const EdgeStyle(shape: EdgeShape.straight).createPath(back, null, from, to), isA<StraightEdgePath>());
      expect(const EdgeStyle(shape: EdgeShape.straight).createPath(edge, 0.15, from, to), isA<CurvedEdgePath>());
      expect(const EdgeStyle(shape: EdgeShape.curved).createPath(edge, null, from, to), isA<CurvedEdgePath>());
    });

    test('orthogonal and right angle keep their shape, self loops always loop', () {
      expect(const EdgeStyle(shape: EdgeShape.orthogonal).createPath(edge, 0.15, from, to), isA<OrthogonalEdgePath>());
      expect(const EdgeStyle(shape: EdgeShape.rightAngle).createPath(edge, null, from, to), isA<RightAngleEdgePath>());
      expect(
        const EdgeStyle(shape: EdgeShape.orthogonal).createPath(const GraphEdge('A', 'A'), null, from, to),
        isA<SelfLoopEdgePath>(),
      );
    });

    test('styled dashes back edges and self loops', () {
      const base = Color(0xFF000000);
      const loopColor = Color(0xFFFF0000);
      EdgeStyle styled(GraphEdge e) => EdgeStyle.styled(e, baseColor: base, backEdgeColor: loopColor);

      expect(styled(edge).dashed, isFalse);
      expect(styled(back).dashed, isTrue);
      expect(styled(back).color.a, closeTo(0.7, 1e-6));
      final loop = styled(const GraphEdge('A', 'A', type: EdgeType.selfLoop));
      expect(loop.dashed, isTrue);
      expect(loop.color, loopColor);
    });
  });

  group('dash', () {
    double length(Path path) => path.computeMetrics().fold(0, (sum, metric) => sum + metric.length);

    test('cuts a line into dashes and gaps', () {
      final line = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      final dashed = EdgePainting.dash(line, 10, 5);

      expect(dashed.computeMetrics().length, 7);
      expect(length(dashed), closeTo(70, 1e-3));
    });

    test('a non-positive dash length leaves the path whole', () {
      final line = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      expect(identical(EdgePainting.dash(line, 0, 5), line), isTrue);
    });
  });
}
