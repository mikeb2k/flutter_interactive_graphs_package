import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Where a label sits along an edge, and the edge's direction there.
@immutable
final class EdgeLabelPosition {
  /// Creates a label position.
  const EdgeLabelPosition(this.position, [this.angle = 0]);

  /// Point on the edge, in the edge's coordinate space.
  final Offset position;

  /// Direction of the edge at [position], in radians.
  final double angle;

  @override
  bool operator ==(Object other) => other is EdgeLabelPosition && other.position == position && other.angle == angle;

  @override
  int get hashCode => Object.hash(position, angle);

  @override
  String toString() => 'EdgeLabelPosition($position, $angle)';
}

/// Named label positions along an edge.
enum LabelPlacement {
  /// A quarter of the way along.
  start(0.25),

  /// Halfway.
  center(0.5),

  /// Three quarters of the way along.
  end(0.75);

  const LabelPlacement(this.offset);

  /// Position along the edge, `0` at the start and `1` at the end.
  final double offset;
}

/// Geometry shared by the edge paths, endpoints and hit testing.
abstract final class EdgeGeometry {
  /// Length of the arrow head along the edge.
  static const double arrowOffset = 8;

  /// Gap between the end of the line and the arrow head.
  static const double arrowGapFromLine = 2;

  /// Half-angle of the default arrow head, in radians.
  static const double arrowAngleSpread = 0.5;

  /// Opacity the line is drawn at relative to its color; arrow heads are opaque.
  static const double lineAlpha = 0.8;

  /// Control point offset of a curved edge, as a fraction of its length.
  static const double curveBend = 0.25;

  /// Height of a self loop as a multiple of its loop radius.
  static const double selfLoopHeightMultiplier = 2;

  /// Spread of a self loop's endpoints along the node's top side, as a fraction of its width.
  static const double selfLoopSpread = 0.3;

  /// Extra spread per unit of bend of a nested self loop.
  static const double selfLoopSpreadPerBend = 0.5;

  /// Largest self loop spread.
  static const double selfLoopMaxSpread = 0.9;

  /// Bend added per nested self loop.
  static const double selfLoopNestedGrowth = 0.5;

  /// Bend between neighbouring parallel edges.
  static const double parallelEdgeBend = 0.15;

  /// Samples used to approximate curves for hit testing.
  static const int curveSamples = 24;

  /// Angle at which a curve with [bend] leaves its start point.
  static double curveTangentAngle(double bend) => math.atan(2 * bend);

  /// How far the line stops short of the arrow tip for a line of [strokeWidth].
  static double arrowShorten(double strokeWidth) => arrowOffset + strokeWidth / 2 + arrowGapFromLine;

  /// Unit vector of [vector], or `null` for a zero vector.
  static Offset? normalize(Offset vector) {
    final length = vector.distance;
    return length == 0 ? null : vector / length;
  }

  /// [direction] rotated by [radians].
  static Offset rotate(Offset direction, double radians) {
    if (radians == 0) return direction;
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Offset(direction.dx * c - direction.dy * s, direction.dx * s + direction.dy * c);
  }

  /// Distance from a box's center to its boundary along the unit vector [direction].
  static double boxRadius(Offset direction, double halfWidth, double halfHeight) {
    if (direction.dx.abs() * halfHeight > direction.dy.abs() * halfWidth) {
      return halfWidth / direction.dx.abs();
    }
    return halfHeight / direction.dy.abs();
  }

  /// Shortest distance from [point] to the segment [a]–[b].
  static double distanceToSegment(Offset point, Offset a, Offset b) {
    final d = b - a;
    final lengthSquared = d.distanceSquared;
    final t = lengthSquared == 0
        ? 0.0
        : (((point - a).dx * d.dx + (point - a).dy * d.dy) / lengthSquared).clamp(0.0, 1.0);
    return (a + d * t - point).distance;
  }

  /// Point of the quadratic Bézier [p0]–[p1]–[p2] at [t].
  static Offset quadraticAt(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return p0 * (u * u) + p1 * (2 * u * t) + p2 * (t * t);
  }

  /// Point of the cubic Bézier [p0]–[p1]–[p2]–[p3] at [t].
  static Offset cubicAt(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t);
  }

  /// Label position on a straight segment at [t].
  static EdgeLabelPosition straightLabel(Offset from, Offset to, double t) {
    final clamped = t.clamp(0.0, 1.0);
    final d = to - from;
    return EdgeLabelPosition(from + d * clamped, math.atan2(d.dy, d.dx));
  }

  /// Label position on a quadratic Bézier at [t].
  static EdgeLabelPosition quadraticLabel(Offset from, Offset control, Offset to, double t) {
    final c = t.clamp(0.0, 1.0);
    final u = 1 - c;
    final tangent = (control - from) * (2 * u) + (to - control) * (2 * c);
    return EdgeLabelPosition(quadraticAt(from, control, to, c), math.atan2(tangent.dy, tangent.dx));
  }

  /// Label position on a cubic Bézier at [t].
  static EdgeLabelPosition cubicLabel(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final c = t.clamp(0.0, 1.0);
    final u = 1 - c;
    final tangent = (p1 - p0) * (3 * u * u) + (p2 - p1) * (6 * u * c) + (p3 - p2) * (3 * c * c);
    return EdgeLabelPosition(cubicAt(p0, p1, p2, p3, c), math.atan2(tangent.dy, tangent.dx));
  }

  /// Label position on the polyline [points] at [t] of its length.
  static EdgeLabelPosition polylineLabel(List<Offset> points, double t) {
    final total = polylineLength(points);
    if (total <= 0) return EdgeLabelPosition(points.first);
    final target = total * t.clamp(0.0, 1.0);
    var walked = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      final d = points[i + 1] - points[i];
      final length = d.distance;
      if (walked + length >= target) {
        final segmentT = length > 0 ? (target - walked) / length : 0.0;
        return EdgeLabelPosition(points[i] + d * segmentT, math.atan2(d.dy, d.dx));
      }
      walked += length;
    }
    final d = points.last - points[points.length - 2];
    return EdgeLabelPosition(points.last, math.atan2(d.dy, d.dx));
  }

  /// Total length of the polyline [points].
  static double polylineLength(List<Offset> points) {
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += (points[i + 1] - points[i]).distance;
    }
    return total;
  }

  /// Length estimate of a quadratic Bézier: (chord + 2 × control polygon) / 3.
  static double quadraticLength(Offset p0, Offset p1, Offset p2) =>
      ((p2 - p0).distance + 2 * ((p1 - p0).distance + (p2 - p1).distance)) / 3;

  /// Length estimate of a cubic Bézier: (chord + 2 × control polygon) / 3.
  static double cubicLength(Offset p0, Offset p1, Offset p2, Offset p3) =>
      ((p3 - p0).distance + 2 * ((p1 - p0).distance + (p2 - p1).distance + (p3 - p2).distance)) / 3;

  /// Rotation that keeps text along an edge upright: angles pointing left are flipped by π.
  /// Returns a value in `[0, 2π)`.
  static double normalizeRotation(double radians) {
    const twoPi = 2 * math.pi;
    final normalized = ((radians % twoPi) + twoPi) % twoPi;
    if (normalized > math.pi / 2 && normalized < 3 * math.pi / 2) {
      return (normalized + math.pi) % twoPi;
    }
    return normalized;
  }
}
