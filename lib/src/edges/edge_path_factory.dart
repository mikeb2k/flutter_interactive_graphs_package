import 'dart:ui';

import 'package:interactive_graphs/src/edges/edge_geometry.dart';
import 'package:interactive_graphs/src/edges/edge_path.dart';

/// Builds [EdgePath]s. With [showArrow] the line stops short of the tip by
/// `EdgeGeometry.arrowShorten(strokeWidth)`, so the arrow head covers its end.
abstract final class EdgePathFactory {
  /// A straight edge from [from] to [to].
  static StraightEdgePath straight(Offset from, Offset to, {bool showArrow = true, double strokeWidth = 3}) {
    final direction = to - from;
    final unit = EdgeGeometry.normalize(direction);
    return StraightEdgePath(
      from: from,
      to: to,
      pathEndpoint: _shortened(to, unit, showArrow, strokeWidth),
      length: direction.distance,
    );
  }

  /// A quadratic curve whose control point sits [bend] × length off the midpoint, to the right of
  /// the direction of travel (in screen coordinates); negative values bend the other way.
  static CurvedEdgePath curved(
    Offset from,
    Offset to, {
    bool showArrow = true,
    double strokeWidth = 3,
    double bend = EdgeGeometry.curveBend,
  }) {
    final direction = to - from;
    final distance = direction.distance;
    if (distance == 0) {
      return CurvedEdgePath(from: from, to: to, controlPoint: from, pathEndpoint: to, length: 0);
    }
    final unit = direction / distance;
    final perpendicular = Offset(-unit.dy, unit.dx);
    final controlPoint = (from + to) / 2 + perpendicular * (distance * bend);
    return CurvedEdgePath(
      from: from,
      to: to,
      controlPoint: controlPoint,
      pathEndpoint: _shortened(to, EdgeGeometry.normalize(to - controlPoint), showArrow, strokeWidth),
      length: EdgeGeometry.quadraticLength(from, controlPoint, to),
    );
  }

  /// A loop that rises `loopRadius × 2 × (1 + bend)` above the midpoint of [from] and [to].
  static SelfLoopEdgePath selfLoop(
    Offset from,
    Offset to, {
    double loopRadius = 40,
    bool showArrow = true,
    double strokeWidth = 3,
    double bend = 0,
  }) {
    final center = (from + to) / 2;
    final controlPoint = center.translate(0, -loopRadius * EdgeGeometry.selfLoopHeightMultiplier * (1 + bend));
    return SelfLoopEdgePath(
      from: from,
      to: to,
      controlPoint: controlPoint,
      pathEndpoint: _shortened(to, EdgeGeometry.normalize(to - controlPoint), showArrow, strokeWidth),
      length: EdgeGeometry.quadraticLength(from, controlPoint, to),
    );
  }

  /// An S-curve with horizontal tangents at both ends; the control points reach [curveFactor] of
  /// the horizontal distance.
  static OrthogonalEdgePath orthogonal(
    Offset from,
    Offset to, {
    double curveFactor = 0.5,
    bool showArrow = true,
    double strokeWidth = 3,
  }) {
    final reach = (to.dx - from.dx) * curveFactor;
    final controlPoint1 = from.translate(reach, 0);
    final controlPoint2 = to.translate(-reach, 0);
    return OrthogonalEdgePath(
      from: from,
      to: to,
      controlPoint1: controlPoint1,
      controlPoint2: controlPoint2,
      pathEndpoint: _shortened(to, EdgeGeometry.normalize(to - controlPoint2), showArrow, strokeWidth),
      length: EdgeGeometry.cubicLength(from, controlPoint1, controlPoint2, to),
      curveFactor: curveFactor,
    );
  }

  /// A path of horizontal and vertical segments routed by [routing].
  static RightAngleEdgePath rightAngle(
    Offset from,
    Offset to,
    RightAngleRouting routing, {
    bool showArrow = true,
    double strokeWidth = 3,
  }) {
    final waypoints = switch (routing) {
      RightAngleRouting.horizontalFirst => [Offset(to.dx, from.dy)],
      RightAngleRouting.verticalFirst => [Offset(from.dx, to.dy)],
      RightAngleRouting.horizontalVerticalHorizontal => [
        Offset((from.dx + to.dx) / 2, from.dy),
        Offset((from.dx + to.dx) / 2, to.dy),
      ],
      RightAngleRouting.verticalHorizontalVertical => [
        Offset(from.dx, (from.dy + to.dy) / 2),
        Offset(to.dx, (from.dy + to.dy) / 2),
      ],
    };
    final last = to - waypoints.last;
    final Offset? arrowDirection;
    if (last.dx.abs() > last.dy.abs()) {
      arrowDirection = Offset(last.dx.sign, 0);
    } else if (last.dy.abs() > last.dx.abs()) {
      arrowDirection = Offset(0, last.dy.sign);
    } else {
      arrowDirection = null;
    }
    return RightAngleEdgePath(
      from: from,
      to: to,
      waypoints: List.unmodifiable(waypoints),
      pathEndpoint: _shortened(to, arrowDirection, showArrow, strokeWidth),
      length: EdgeGeometry.polylineLength([from, ...waypoints, to]),
      arrowDirection: arrowDirection,
    );
  }

  static Offset _shortened(Offset tip, Offset? direction, bool showArrow, double strokeWidth) {
    if (!showArrow || direction == null) return tip;
    return tip - direction * EdgeGeometry.arrowShorten(strokeWidth);
  }
}
