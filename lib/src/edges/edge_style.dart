import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:interactive_graphs/src/edges/edge_geometry.dart';
import 'package:interactive_graphs/src/edges/edge_path.dart';
import 'package:interactive_graphs/src/edges/edge_path_factory.dart';
import 'package:interactive_graphs/src/model/graph_edge.dart';
import 'package:interactive_graphs/src/theme/graph_theme.dart';

/// Draws an arrow head with its tip at [tip], pointing along the unit vector [direction].
typedef ArrowPainter = void Function(Canvas canvas, Offset tip, Offset direction, Color color, double size);

/// Built-in [ArrowPainter]s.
abstract final class ArrowPainters {
  /// Filled triangle, the default.
  static void triangle(Canvas canvas, Offset tip, Offset direction, Color color, double size) {
    final angle = math.atan2(direction.dy, direction.dx);
    const spread = EdgeGeometry.arrowAngleSpread;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - size * math.cos(angle - spread), tip.dy - size * math.sin(angle - spread))
      ..lineTo(tip.dx - size * math.cos(angle + spread), tip.dy - size * math.sin(angle + spread))
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 1));
  }

  /// Two open strokes, like `>`.
  static void open(Canvas canvas, Offset tip, Offset direction, Color color, double size) {
    final angle = math.atan2(direction.dy, direction.dx);
    const spread = EdgeGeometry.arrowAngleSpread;
    final path = Path()
      ..moveTo(tip.dx - size * math.cos(angle - spread), tip.dy - size * math.sin(angle - spread))
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - size * math.cos(angle + spread), tip.dy - size * math.sin(angle + spread));
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, size / 8)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Filled circle centered a radius back from the tip.
  static void circle(Canvas canvas, Offset tip, Offset direction, Color color, double size) {
    final radius = size / 3;
    canvas.drawCircle(tip - direction * radius, radius, Paint()..color = color.withValues(alpha: 1));
  }

  /// Draws nothing.
  static void none(Canvas canvas, Offset tip, Offset direction, Color color, double size) {}
}

/// Geometry an [EdgeStyle] draws an edge with.
enum EdgeShape {
  /// Straight, curved for back edges; parallel edges fan out.
  auto,

  /// Straight; parallel edges still fan out.
  straight,

  /// Always curved.
  curved,

  /// S-curve with horizontal ends.
  orthogonal,

  /// Horizontal and vertical segments, routed by the anchor sides.
  rightAngle;

  /// Whether parallel edges with this shape spread out.
  bool get fansOut => this == EdgeShape.auto || this == EdgeShape.straight || this == EdgeShape.curved;
}

/// How the batched edge layer draws one edge. Also usable with `EdgeLine`.
@immutable
final class EdgeStyle {
  /// Creates a style.
  const EdgeStyle({
    this.color = GraphThemeData.defaultEdgeColor,
    this.strokeWidth = 3,
    this.showArrow = true,
    this.dashed = false,
    this.dashLength = 10,
    this.gapLength = 5,
    this.shape = EdgeShape.auto,
    this.loopRadius = 40,
    this.curveFactor = 0.5,
    this.arrowSize = 16,
    this.arrowPainter = ArrowPainters.triangle,
  });

  /// Kuiver's default look: [baseColor] for edges, dashed and faded back edges, dashed self loops in
  /// [backEdgeColor].
  factory EdgeStyle.styled(
    GraphEdge edge, {
    required Color baseColor,
    required Color backEdgeColor,
    double strokeWidth = 3,
    EdgeShape shape = EdgeShape.auto,
    ArrowPainter arrowPainter = ArrowPainters.triangle,
  }) {
    final (color, dashed) = switch (edge.type) {
      EdgeType.selfLoop => (backEdgeColor, true),
      EdgeType.back => (baseColor.withValues(alpha: baseColor.a * 0.7), true),
      _ => (baseColor, false),
    };
    return EdgeStyle(color: color, strokeWidth: strokeWidth, dashed: dashed, shape: shape, arrowPainter: arrowPainter);
  }

  /// Line and arrow color; the line is drawn at 80 % of its opacity.
  final Color color;

  /// Line width.
  final double strokeWidth;

  /// Whether to draw an arrow head at the end.
  final bool showArrow;

  /// Whether the line is dashed.
  final bool dashed;

  /// Dash length when [dashed].
  final double dashLength;

  /// Gap length when [dashed].
  final double gapLength;

  /// Geometry of the edge.
  final EdgeShape shape;

  /// Self loop radius.
  final double loopRadius;

  /// Reach of the control points of [EdgeShape.orthogonal].
  final double curveFactor;

  /// Arrow head size.
  final double arrowSize;

  /// Draws the arrow head.
  final ArrowPainter arrowPainter;

  /// The path of [edge] from [from] to [to] in this style. [bend] comes from `ParallelEdges`.
  EdgePath createPath(GraphEdge edge, double? bend, Offset from, Offset to) {
    if (edge.isSelfLoop) {
      return EdgePathFactory.selfLoop(
        from,
        to,
        loopRadius: loopRadius,
        showArrow: showArrow,
        strokeWidth: strokeWidth,
        bend: bend ?? 0,
      );
    }
    return switch (shape) {
      EdgeShape.auto || EdgeShape.straight when bend != null && bend != 0 => _curved(from, to, bend),
      EdgeShape.auto when bend == null && edge.type == EdgeType.back => _curved(from, to, EdgeGeometry.curveBend),
      EdgeShape.auto || EdgeShape.straight => EdgePathFactory.straight(
        from,
        to,
        showArrow: showArrow,
        strokeWidth: strokeWidth,
      ),
      EdgeShape.curved => _curved(from, to, bend ?? EdgeGeometry.curveBend),
      EdgeShape.orthogonal => EdgePathFactory.orthogonal(
        from,
        to,
        curveFactor: curveFactor,
        showArrow: showArrow,
        strokeWidth: strokeWidth,
      ),
      EdgeShape.rightAngle => EdgePathFactory.rightAngle(
        from,
        to,
        RightAngleRouting.fromAnchorSides(
          AnchorSide.fromAnchorId(edge.fromAnchor),
          AnchorSide.fromAnchorId(edge.toAnchor),
        ),
        showArrow: showArrow,
        strokeWidth: strokeWidth,
      ),
    };
  }

  EdgePath _curved(Offset from, Offset to, double bend) =>
      EdgePathFactory.curved(from, to, showArrow: showArrow, strokeWidth: strokeWidth, bend: bend);

  /// Returns a copy with the given fields replaced.
  EdgeStyle copyWith({
    Color? color,
    double? strokeWidth,
    bool? showArrow,
    bool? dashed,
    double? dashLength,
    double? gapLength,
    EdgeShape? shape,
    double? loopRadius,
    double? curveFactor,
    double? arrowSize,
    ArrowPainter? arrowPainter,
  }) => EdgeStyle(
    color: color ?? this.color,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    showArrow: showArrow ?? this.showArrow,
    dashed: dashed ?? this.dashed,
    dashLength: dashLength ?? this.dashLength,
    gapLength: gapLength ?? this.gapLength,
    shape: shape ?? this.shape,
    loopRadius: loopRadius ?? this.loopRadius,
    curveFactor: curveFactor ?? this.curveFactor,
    arrowSize: arrowSize ?? this.arrowSize,
    arrowPainter: arrowPainter ?? this.arrowPainter,
  );

  @override
  bool operator ==(Object other) =>
      other is EdgeStyle &&
      other.color == color &&
      other.strokeWidth == strokeWidth &&
      other.showArrow == showArrow &&
      other.dashed == dashed &&
      other.dashLength == dashLength &&
      other.gapLength == gapLength &&
      other.shape == shape &&
      other.loopRadius == loopRadius &&
      other.curveFactor == curveFactor &&
      other.arrowSize == arrowSize &&
      other.arrowPainter == arrowPainter;

  @override
  int get hashCode => Object.hash(
    color,
    strokeWidth,
    showArrow,
    dashed,
    dashLength,
    gapLength,
    shape,
    loopRadius,
    curveFactor,
    arrowSize,
    arrowPainter,
  );
}

/// Strokes [EdgePath]s on a canvas.
abstract final class EdgePainting {
  /// Draws [path] in [style]: the line (dashed if asked, at 80 % opacity) and the arrow head.
  ///
  /// A caller that draws the same edge again and again can compute its [line] once and pass it in.
  static void paint(Canvas canvas, EdgePath path, EdgeStyle style, {Path? line}) {
    final paint = Paint()
      ..color = style.color.withValues(alpha: style.color.a * EdgeGeometry.lineAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line ?? EdgePainting.line(path, style), paint);

    final direction = path.arrowDirection;
    if (style.showArrow && direction != null && path.length > 0) {
      style.arrowPainter(canvas, path.to, direction, style.color, style.arrowSize);
    }
  }

  /// The line [paint] strokes for [path] in [style]: the path itself, or its dashes.
  static Path line(EdgePath path, EdgeStyle style) {
    final whole = path.toPath();
    if (!style.dashed) return whole;
    return dash(whole, style.dashLength, style.gapLength);
  }

  /// [source] cut into dashes of [dashLength] separated by [gapLength].
  static Path dash(Path source, double dashLength, double gapLength) {
    if (dashLength <= 0) return source;
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        dashed.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + math.max(gapLength, 0);
      }
    }
    return dashed;
  }
}
