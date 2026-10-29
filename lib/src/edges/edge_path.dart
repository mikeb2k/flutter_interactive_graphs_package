import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:interactive_graphs/src/edges/edge_geometry.dart';

/// Geometry of a drawn edge: where it starts, where its line ends ([pathEndpoint], short of the
/// arrow tip [to]), its length, and everything derived from it (label positions, hit distance,
/// bounds, the stroke [Path]). One source of truth for drawing, labels and hit testing.
///
/// Create paths with `EdgePathFactory`. Coordinates are in the space of the edge layer.
@immutable
sealed class EdgePath {
  const EdgePath({required this.from, required this.to, required this.pathEndpoint, required this.length});

  /// Start of the edge.
  final Offset from;

  /// End of the edge: the arrow tip.
  final Offset to;

  /// Where the stroked line ends, short of [to] when the edge has an arrow.
  final Offset pathEndpoint;

  /// Length of the edge (an estimate for curves).
  final double length;

  /// Unit direction of the edge at [to], for the arrow head, or `null` when it has none.
  Offset? get arrowDirection;

  /// The line to stroke, from [from] to [pathEndpoint].
  Path toPath();

  /// Label position at [t] (`0` start, `1` end; clamped), or `null` when the edge is shorter than
  /// [minLength].
  EdgeLabelPosition? labelPositionAt(double t, {double minLength = 0}) {
    if (length < minLength) return null;
    return _labelAt(t);
  }

  EdgeLabelPosition _labelAt(double t);

  /// Shortest distance from [point] to the edge, arrow head included.
  double distanceTo(Offset point) =>
      math.min(EdgeGeometry.distanceToSegment(point, pathEndpoint, to), _lineDistanceTo(point));

  double _lineDistanceTo(Offset point);

  /// Points the line passes through or is pulled towards; the bounds contain them all.
  Iterable<Offset> get _extremePoints;

  /// Box containing the drawn edge, grown by half the stroke and the arrow head.
  Rect bounds({double strokeWidth = 3, double arrowSize = 16, bool showArrow = true, double extraPadding = 0}) {
    var left = from.dx;
    var top = from.dy;
    var right = from.dx;
    var bottom = from.dy;
    for (final point in [to, pathEndpoint, ..._extremePoints]) {
      left = math.min(left, point.dx);
      top = math.min(top, point.dy);
      right = math.max(right, point.dx);
      bottom = math.max(bottom, point.dy);
    }
    final padding = strokeWidth / 2 + (showArrow ? EdgeGeometry.arrowOffset + arrowSize : 0) + extraPadding;
    return Rect.fromLTRB(left - padding, top - padding, right + padding, bottom + padding);
  }

  double _sampledDistance(Offset point, Offset Function(double t) at) {
    var min = double.infinity;
    var previous = from;
    for (var i = 1; i <= EdgeGeometry.curveSamples; i++) {
      final next = at(i / EdgeGeometry.curveSamples);
      min = math.min(min, EdgeGeometry.distanceToSegment(point, previous, next));
      previous = next;
    }
    return min;
  }
}

/// A straight edge.
final class StraightEdgePath extends EdgePath {
  /// Creates a straight path. Prefer `EdgePathFactory.straight`.
  const StraightEdgePath({required super.from, required super.to, required super.pathEndpoint, required super.length});

  @override
  Offset? get arrowDirection => EdgeGeometry.normalize(to - from);

  @override
  Path toPath() => Path()
    ..moveTo(from.dx, from.dy)
    ..lineTo(pathEndpoint.dx, pathEndpoint.dy);

  @override
  EdgeLabelPosition _labelAt(double t) => EdgeGeometry.straightLabel(from, pathEndpoint, t);

  @override
  double _lineDistanceTo(Offset point) => EdgeGeometry.distanceToSegment(point, from, pathEndpoint);

  @override
  Iterable<Offset> get _extremePoints => const [];

  @override
  String toString() => 'StraightEdgePath($from -> $to)';
}

/// A quadratic Bézier edge: [CurvedEdgePath] or [SelfLoopEdgePath].
sealed class QuadraticEdgePath extends EdgePath {
  /// Creates a quadratic path.
  const QuadraticEdgePath({
    required super.from,
    required super.to,
    required this.controlPoint,
    required super.pathEndpoint,
    required super.length,
  });

  /// Control point of the curve.
  final Offset controlPoint;

  @override
  Offset? get arrowDirection => EdgeGeometry.normalize(to - controlPoint);

  @override
  Path toPath() => Path()
    ..moveTo(from.dx, from.dy)
    ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, pathEndpoint.dx, pathEndpoint.dy);

  @override
  EdgeLabelPosition _labelAt(double t) => EdgeGeometry.quadraticLabel(from, controlPoint, pathEndpoint, t);

  @override
  double _lineDistanceTo(Offset point) =>
      _sampledDistance(point, (t) => EdgeGeometry.quadraticAt(from, controlPoint, pathEndpoint, t));

  @override
  Iterable<Offset> get _extremePoints => [controlPoint];
}

/// A quadratic Bézier edge, used for back edges and fanned-out parallel edges.
final class CurvedEdgePath extends QuadraticEdgePath {
  /// Creates a curved path. Prefer `EdgePathFactory.curved`.
  const CurvedEdgePath({
    required super.from,
    required super.to,
    required super.controlPoint,
    required super.pathEndpoint,
    required super.length,
  });

  @override
  String toString() => 'CurvedEdgePath($from -> $to via $controlPoint)';
}

/// A loop from a node back to itself, a quadratic Bézier above the node.
final class SelfLoopEdgePath extends QuadraticEdgePath {
  /// Creates a self-loop path. Prefer `EdgePathFactory.selfLoop`.
  const SelfLoopEdgePath({
    required super.from,
    required super.to,
    required super.controlPoint,
    required super.pathEndpoint,
    required super.length,
  });

  @override
  String toString() => 'SelfLoopEdgePath($from -> $to via $controlPoint)';
}

/// A cubic Bézier S-curve that leaves and enters horizontally, for left-to-right hierarchies.
final class OrthogonalEdgePath extends EdgePath {
  /// Creates an orthogonal path. Prefer `EdgePathFactory.orthogonal`.
  const OrthogonalEdgePath({
    required super.from,
    required super.to,
    required this.controlPoint1,
    required this.controlPoint2,
    required super.pathEndpoint,
    required super.length,
    required this.curveFactor,
  });

  /// Control point next to [from].
  final Offset controlPoint1;

  /// Control point next to [to].
  final Offset controlPoint2;

  /// How far the control points reach horizontally, as a fraction of the horizontal distance.
  final double curveFactor;

  @override
  Offset? get arrowDirection => EdgeGeometry.normalize(to - controlPoint2);

  @override
  Path toPath() => Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      pathEndpoint.dx,
      pathEndpoint.dy,
    );

  @override
  EdgeLabelPosition _labelAt(double t) => EdgeGeometry.cubicLabel(from, controlPoint1, controlPoint2, pathEndpoint, t);

  @override
  double _lineDistanceTo(Offset point) =>
      _sampledDistance(point, (t) => EdgeGeometry.cubicAt(from, controlPoint1, controlPoint2, pathEndpoint, t));

  @override
  Iterable<Offset> get _extremePoints => [controlPoint1, controlPoint2];

  @override
  String toString() => 'OrthogonalEdgePath($from -> $to)';
}

/// A path of horizontal and vertical segments (draw.io style).
final class RightAngleEdgePath extends EdgePath {
  /// Creates a right-angle path. Prefer `EdgePathFactory.rightAngle`.
  const RightAngleEdgePath({
    required super.from,
    required super.to,
    required this.waypoints,
    required super.pathEndpoint,
    required super.length,
    required this.arrowDirection,
  });

  /// Corners between [from] and [to].
  final List<Offset> waypoints;

  @override
  final Offset? arrowDirection;

  List<Offset> get _linePoints => [from, ...waypoints, pathEndpoint];

  @override
  Path toPath() {
    final path = Path()..moveTo(from.dx, from.dy);
    for (final point in [...waypoints, pathEndpoint]) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  @override
  EdgeLabelPosition _labelAt(double t) => EdgeGeometry.polylineLabel(_linePoints, t);

  @override
  double _lineDistanceTo(Offset point) {
    final points = _linePoints;
    var min = double.infinity;
    for (var i = 0; i < points.length - 1; i++) {
      min = math.min(min, EdgeGeometry.distanceToSegment(point, points[i], points[i + 1]));
    }
    return min;
  }

  @override
  Iterable<Offset> get _extremePoints => waypoints;

  @override
  String toString() => 'RightAngleEdgePath($from -> $to via $waypoints)';
}

/// Side of a node an anchor sits on, inferred from its id.
enum AnchorSide {
  /// `left`, `l`, `west`, `w` or `start`.
  left,

  /// `right`, `r`, `east`, `e` or `end`.
  right,

  /// `top`, `t`, `north`, `n` or `up`.
  top,

  /// `bottom`, `b`, `south`, `s` or `down`.
  bottom;

  /// The side named by [anchorId] (case-insensitive, trimmed), or `null`.
  static AnchorSide? fromAnchorId(String? anchorId) => switch (anchorId?.trim().toLowerCase()) {
    'left' || 'l' || 'west' || 'w' || 'start' => AnchorSide.left,
    'right' || 'r' || 'east' || 'e' || 'end' => AnchorSide.right,
    'top' || 't' || 'north' || 'n' || 'up' => AnchorSide.top,
    'bottom' || 'b' || 'south' || 's' || 'down' => AnchorSide.bottom,
    _ => null,
  };

  /// Whether the side is [left] or [right].
  bool get isHorizontal => this == AnchorSide.left || this == AnchorSide.right;
}

/// How a [RightAngleEdgePath] turns between its ends.
enum RightAngleRouting {
  /// Horizontal, then vertical (one corner).
  horizontalFirst,

  /// Vertical, then horizontal (one corner).
  verticalFirst,

  /// Horizontal, vertical, horizontal (two corners).
  horizontalVerticalHorizontal,

  /// Vertical, horizontal, vertical (two corners).
  verticalHorizontalVertical;

  /// Routing that leaves and enters along the anchor sides.
  static RightAngleRouting fromAnchorSides(AnchorSide? fromSide, AnchorSide? toSide) {
    if (fromSide != null && toSide != null) {
      return switch ((fromSide.isHorizontal, toSide.isHorizontal)) {
        (true, true) => RightAngleRouting.horizontalVerticalHorizontal,
        (false, false) => RightAngleRouting.verticalHorizontalVertical,
        (true, false) => RightAngleRouting.horizontalFirst,
        (false, true) => RightAngleRouting.verticalFirst,
      };
    }
    final known = fromSide ?? toSide;
    if (known == null || known.isHorizontal) return RightAngleRouting.horizontalVerticalHorizontal;
    return RightAngleRouting.verticalHorizontalVertical;
  }
}
