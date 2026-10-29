import 'dart:math' as math;

import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/showcase/models/edge_state.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_edge_paths.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_layout.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/edge_label_pill.dart';
import 'package:material_ui/material_ui.dart';

/// Edge of the showcase: a thin line that takes on [color] once lit, marching dashes for loops,
/// dots while parcels flow, a notched arrow head and an optional label pill. Emphasis, dimming
/// and the color change animate.
class ShowcaseEdge extends ImplicitlyAnimatedWidget {
  /// Creates the edge.
  const ShowcaseEdge({
    super.key,
    required this.details,
    required this.style,
    required this.color,
    required this.idleColor,
    required this.state,
    required this.dashed,
    required this.emphasized,
    required this.dimmed,
    required this.flowPhase,
    this.label,
    this.labelAt = 0.5,
    super.duration = const Duration(milliseconds: 300),
    super.curve = Curves.easeOut,
  });

  /// The edge and its end points.
  final EdgeDetails details;

  /// Shape of the edge.
  final ShowcaseEdgeStyle style;

  /// Color of the edge once lit or emphasized, and of the flowing dots.
  final Color color;

  /// Color of the edge before its steps run.
  final Color idleColor;

  /// How lit up the edge is.
  final EdgeState state;

  /// Whether the edge is dashed, for loops.
  final bool dashed;

  /// Whether the edge is hovered or selected.
  final bool emphasized;

  /// Whether another node or edge has the focus.
  final bool dimmed;

  /// Shared 0..1 phase of the dots and dashes, read while painting only.
  final Animation<double> flowPhase;

  /// Label text, none when `null`.
  final String? label;

  /// Where the label sits along the edge, 0 at the start and 1 at the end.
  final double labelAt;

  @override
  AnimatedWidgetBaseState<ShowcaseEdge> createState() => _ShowcaseEdgeState();
}

class _ShowcaseEdgeState extends AnimatedWidgetBaseState<ShowcaseEdge> {
  Tween<double>? _emphasis;
  Tween<double>? _alpha;
  ColorTween? _tint;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _emphasis =
        visitor(_emphasis, _emphasisTarget(), (value) => Tween<double>(begin: value as double)) as Tween<double>?;
    _alpha = visitor(_alpha, _alphaTarget(), (value) => Tween<double>(begin: value as double)) as Tween<double>?;
    _tint = visitor(_tint, _tintTarget(), (value) => ColorTween(begin: value as Color)) as ColorTween?;
  }

  @override
  Widget build(BuildContext context) {
    final path = ShowcaseEdgePaths.create(widget.details, widget.style);
    EdgeHitScope.report(context, path);
    final visibility = _alpha?.evaluate(animation) ?? 1;
    final labelPosition = _labelPosition(path);
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: _ShowcaseEdgePainter(
            path: path,
            lineColor: _tint?.evaluate(animation) ?? widget.color,
            flowColor: widget.color,
            strength: _emphasis?.evaluate(animation) ?? 0,
            visibility: visibility,
            dashed: widget.dashed,
            flowing: widget.state == EdgeState.flowing,
            flowPhase: widget.flowPhase,
          ),
        ),
        if (labelPosition != null)
          EdgeLabelPositioned(
            position: labelPosition,
            child: Opacity(
              opacity: visibility,
              child: EdgeLabelPill(label: widget.label ?? ''),
            ),
          ),
      ],
    );
  }

  double _emphasisTarget() {
    if (widget.emphasized) return 1;
    return 0;
  }

  double _alphaTarget() {
    if (widget.dimmed) return 0.2;
    return 1;
  }

  Color _tintTarget() {
    if (widget.state == EdgeState.idle && !widget.emphasized) return widget.idleColor;
    return widget.color;
  }

  /// Where the label goes, `null` without a label or on edges shorter than 70 pixels.
  EdgeLabelPosition? _labelPosition(EdgePath path) {
    if (widget.label == null) return null;
    return path.labelPositionAt(widget.labelAt, minLength: 70);
  }
}

/// Paints the line, its state layer, the arrow head and the flowing dots of a [ShowcaseEdge].
class _ShowcaseEdgePainter extends CustomPainter {
  _ShowcaseEdgePainter({
    required this.path,
    required this.lineColor,
    required this.flowColor,
    required this.strength,
    required this.visibility,
    required this.dashed,
    required this.flowing,
    required this.flowPhase,
  }) : super(repaint: flowing ? flowPhase : null);

  final EdgePath path;
  final Color lineColor;
  final Color flowColor;
  final double strength;
  final double visibility;
  final bool dashed;
  final bool flowing;
  final Animation<double> flowPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final line = _linePath();

    // Soft state layer behind hovered and selected edges
    if (strength > 0) {
      canvas.drawPath(line, _stroke(lineColor.withValues(alpha: lineColor.a * 0.16 * strength * visibility), 10));
    }

    // March the dashes of a loop while it is active
    var drawn = line;
    if (dashed) {
      final phase = flowing ? -flowPhase.value * ShowcaseEdgePaths.dashPeriod * 3 : 0.0;
      drawn = _dashed(line, phase);
    }
    final color = lineColor.withValues(alpha: lineColor.a * visibility);
    canvas.drawPath(drawn, _stroke(color, ShowcaseEdgePaths.strokeWidth + 1.5 * strength));
    _drawArrowHead(canvas, color, 9 + 2 * strength);

    if (flowing) _drawParticles(canvas);
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// The line to stroke, with rounded corners on right-angle paths.
  Path _linePath() {
    final edgePath = path;
    if (edgePath is! RightAngleEdgePath) return edgePath.toPath();
    final points = [edgePath.from, ...edgePath.waypoints, edgePath.pathEndpoint];
    final result = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final corner = points[i];
      final incoming = corner - points[i - 1];
      final outgoing = points[i + 1] - corner;
      final radius = math.min(ShowcaseEdgePaths.cornerRadius, math.min(incoming.distance, outgoing.distance) / 2);
      if (radius <= 0) {
        result.lineTo(corner.dx, corner.dy);
        continue;
      }
      final start = corner - incoming / incoming.distance * radius;
      final end = corner + outgoing / outgoing.distance * radius;
      result
        ..lineTo(start.dx, start.dy)
        ..quadraticBezierTo(corner.dx, corner.dy, end.dx, end.dy);
    }
    return result..lineTo(points.last.dx, points.last.dy);
  }

  /// [source] cut into dashes, the pattern shifted by [phase] like a dash path effect.
  Path _dashed(Path source, double phase) {
    const period = ShowcaseEdgePaths.dashPeriod;
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      for (var start = (-phase) % period - period; start < metric.length; start += period) {
        final from = math.max(start, 0.0);
        final to = math.min(start + ShowcaseEdgePaths.dashLength, metric.length);
        if (to > from) dashed.addPath(metric.extractPath(from, to), Offset.zero);
      }
    }
    return dashed;
  }

  /// Notched arrow head at the end of the path.
  void _drawArrowHead(Canvas canvas, Color color, double length) {
    final direction = path.arrowDirection ?? EdgeGeometry.normalize(path.to - path.from);
    if (direction == null) return;
    final normal = Offset(-direction.dy, direction.dx) * (length * 0.55);
    final tip = path.to;
    final base = tip - direction * length;
    final notch = tip - direction * (length * 0.7);
    final arrow = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + normal.dx, base.dy + normal.dy)
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(base.dx - normal.dx, base.dy - normal.dy)
      ..close();
    canvas.drawPath(arrow, Paint()..color = color);
  }

  /// Dots travelling from start to end, fading in and out at the nodes.
  void _drawParticles(Canvas canvas) {
    final count = (path.length / 80).floor().clamp(1, 6);
    final phase = flowPhase.value;
    for (var index = 0; index < count; index++) {
      final t = (phase + index / count) % 1;
      final point = path.labelPositionAt(t)?.position;
      if (point == null) continue;
      final fade = math.min(math.min(t, 1 - t) * 6, 1.0) * visibility;
      canvas.drawCircle(point, 4, Paint()..color = flowColor.withValues(alpha: flowColor.a * fade));
    }
  }

  @override
  bool shouldRepaint(_ShowcaseEdgePainter oldDelegate) =>
      oldDelegate.path != path ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.flowColor != flowColor ||
      oldDelegate.strength != strength ||
      oldDelegate.visibility != visibility ||
      oldDelegate.dashed != dashed ||
      oldDelegate.flowing != flowing;

  @override
  bool? hitTest(Offset position) => false;
}
