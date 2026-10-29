import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

void main() {
  const from = Offset(0, 0);
  const to = Offset(100, 0);
  // Arrow head offset (8) + half the default stroke (1.5) + gap (2)
  const shorten = 11.5;

  group('straight', () {
    test('ends short of the tip to leave room for the arrow', () {
      final path = EdgePathFactory.straight(from, to);

      expect(path.length, 100);
      expect(path.pathEndpoint.dx, closeTo(100 - shorten, 1e-9));
      expect(path.arrowDirection, const Offset(1, 0));
      expect(EdgePathFactory.straight(from, to, showArrow: false).pathEndpoint, to);
    });

    test('label positions follow the line and hide on short edges', () {
      final path = EdgePathFactory.straight(from, to);

      expect(path.labelPositionAt(0)!.position, from);
      expect(path.labelPositionAt(0.5)!.position.dx, closeTo((100 - shorten) / 2, 1e-9));
      expect(path.labelPositionAt(2)!.position, path.pathEndpoint, reason: 'clamped to 1');
      expect(path.labelPositionAt(0.5)!.angle, 0);
      expect(path.labelPositionAt(0.5, minLength: 120), isNull);
    });

    test('distance to a point measures to the segment', () {
      final path = EdgePathFactory.straight(from, to);

      expect(path.distanceTo(const Offset(50, 5)), closeTo(5, 1e-9));
      expect(path.distanceTo(const Offset(-3, 4)), closeTo(5, 1e-9));
      expect(path.distanceTo(const Offset(100, 0)), closeTo(0, 1e-9), reason: 'the arrow head counts');
    });
  });

  group('curved', () {
    test('bends to the side of the perpendicular in proportion to its length', () {
      final path = EdgePathFactory.curved(from, to, bend: 0.25);

      expect(path.controlPoint, const Offset(50, 25));
      expect(path.length, greaterThan(100));
      expect(EdgePathFactory.curved(from, to, bend: -0.25).controlPoint, const Offset(50, -25));
    });

    test('the middle label sits on the curve, the arrow follows the end tangent', () {
      final path = EdgePathFactory.curved(from, to, bend: 0.25, showArrow: false);

      expect(path.labelPositionAt(0.5)!.position, const Offset(50, 12.5));
      expect(path.arrowDirection!.dy, lessThan(0));
      expect(path.distanceTo(const Offset(50, 12.5)), closeTo(0, 0.5));
      expect(path.distanceTo(const Offset(50, 0)), greaterThan(10));
    });

    test('a degenerate curve collapses to a point', () {
      final path = EdgePathFactory.curved(from, from);

      expect(path.length, 0);
      expect(path.controlPoint, from);
    });
  });

  group('self loop', () {
    test('rises above its endpoints, higher with a bend', () {
      final flat = EdgePathFactory.selfLoop(const Offset(-10, 0), const Offset(10, 0));
      final nested = EdgePathFactory.selfLoop(const Offset(-10, 0), const Offset(10, 0), bend: 0.5);

      expect(flat.controlPoint, const Offset(0, -80));
      expect(nested.controlPoint.dy, lessThan(flat.controlPoint.dy));
    });
  });

  group('orthogonal', () {
    test('leaves and enters horizontally', () {
      final path = EdgePathFactory.orthogonal(from, const Offset(100, 100), showArrow: false);

      expect(path.controlPoint1, const Offset(50, 0));
      expect(path.controlPoint2, const Offset(50, 100));
      expect(path.arrowDirection, const Offset(1, 0));
      expect(path.labelPositionAt(0.5)!.position, const Offset(50, 50));
    });
  });

  group('right angle', () {
    test('routes through waypoints that only turn by right angles', () {
      const end = Offset(100, 60);
      final hvh = EdgePathFactory.rightAngle(from, end, RightAngleRouting.horizontalVerticalHorizontal);
      final vhv = EdgePathFactory.rightAngle(from, end, RightAngleRouting.verticalHorizontalVertical);
      final hFirst = EdgePathFactory.rightAngle(from, end, RightAngleRouting.horizontalFirst);
      final vFirst = EdgePathFactory.rightAngle(from, end, RightAngleRouting.verticalFirst);

      expect(hvh.waypoints, const [Offset(50, 0), Offset(50, 60)]);
      expect(vhv.waypoints, const [Offset(0, 30), Offset(100, 30)]);
      expect(hFirst.waypoints, const [Offset(100, 0)]);
      expect(vFirst.waypoints, const [Offset(0, 60)]);
      expect(hvh.length, 160);
      expect(hvh.arrowDirection, const Offset(1, 0));
      expect(hFirst.arrowDirection, const Offset(0, 1));
    });

    test('labels walk the segments by length', () {
      final path = EdgePathFactory.rightAngle(
        from,
        const Offset(100, 60),
        RightAngleRouting.horizontalVerticalHorizontal,
        showArrow: false,
      );

      expect(path.labelPositionAt(0.5)!.position, const Offset(50, 30));
      expect(path.labelPositionAt(0.5)!.angle, closeTo(math.pi / 2, 1e-9));
      expect(path.distanceTo(const Offset(50, 30)), closeTo(0, 1e-9));
    });

    test('routing follows the anchor sides', () {
      expect(
        RightAngleRouting.fromAnchorSides(AnchorSide.right, AnchorSide.left),
        RightAngleRouting.horizontalVerticalHorizontal,
      );
      expect(
        RightAngleRouting.fromAnchorSides(AnchorSide.bottom, AnchorSide.top),
        RightAngleRouting.verticalHorizontalVertical,
      );
      expect(RightAngleRouting.fromAnchorSides(AnchorSide.right, AnchorSide.top), RightAngleRouting.horizontalFirst);
      expect(RightAngleRouting.fromAnchorSides(AnchorSide.top, AnchorSide.left), RightAngleRouting.verticalFirst);
      expect(RightAngleRouting.fromAnchorSides(null, AnchorSide.bottom), RightAngleRouting.verticalHorizontalVertical);
      expect(RightAngleRouting.fromAnchorSides(null, null), RightAngleRouting.horizontalVerticalHorizontal);
      expect(AnchorSide.fromAnchorId(' East '), AnchorSide.right);
      expect(AnchorSide.fromAnchorId('custom'), isNull);
    });
  });

  test('bounds contain every point of the path plus stroke and arrow', () {
    final paths = <EdgePath>[
      EdgePathFactory.straight(from, to),
      EdgePathFactory.curved(from, to),
      EdgePathFactory.selfLoop(const Offset(-10, 0), const Offset(10, 0)),
      EdgePathFactory.orthogonal(from, const Offset(100, 100)),
      EdgePathFactory.rightAngle(from, const Offset(100, 60), RightAngleRouting.verticalFirst),
    ];
    for (final path in paths) {
      final bounds = path.bounds(strokeWidth: 3, arrowSize: 16);
      for (var t = 0.0; t <= 1; t += 0.1) {
        expect(bounds.contains(path.labelPositionAt(t, minLength: 0)!.position), isTrue, reason: '$path at $t');
      }
      expect(bounds.contains(path.to), isTrue);
    }
  });

  test('normalizeRotation keeps label text upright', () {
    expect(EdgeGeometry.normalizeRotation(0), 0);
    expect(EdgeGeometry.normalizeRotation(math.pi), closeTo(0, 1e-9));
    expect(EdgeGeometry.normalizeRotation(-math.pi / 4), closeTo(7 * math.pi / 4, 1e-9));
    expect(EdgeGeometry.normalizeRotation(3 * math.pi / 4), closeTo(7 * math.pi / 4, 1e-9));
  });
}
