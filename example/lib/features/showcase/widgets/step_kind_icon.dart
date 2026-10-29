import 'dart:math' as math;

import 'package:interactive_graphs_example/features/showcase/models/step_spec.dart';
import 'package:material_ui/material_ui.dart';

/// Icon of a step on a rounded shape per kind. While the step is in progress the shape morphs
/// into a burst and turns slowly.
class StepKindIcon extends StatefulWidget {
  /// Creates the icon.
  const StepKindIcon({super.key, required this.kind, required this.icon, required this.active});

  /// Who handles the step: sets the shape and color.
  final StepKind kind;

  /// The step's icon.
  final IconData icon;

  /// Whether the step is in progress.
  final bool active;

  @override
  State<StepKindIcon> createState() => _StepKindIconState();
}

class _StepKindIconState extends State<StepKindIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncSpin();
  }

  @override
  void didUpdateWidget(StepKindIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncSpin();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (color, onColor) = _colors(Theme.of(context).colorScheme);
    return SizedBox.square(
      dimension: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _spin,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _morphTarget()),
              duration: _morphDuration(),
              curve: Curves.easeInOutCubic,
              builder: (context, progress, _) => CustomPaint(
                size: const Size.square(40),
                painter: _StepShapePainter(kind: widget.kind, burst: progress, color: color),
              ),
            ),
          ),
          Icon(widget.icon, size: 20, color: onColor),
        ],
      ),
    );
  }

  void _syncSpin() {
    if (widget.active && !_reduceMotion) {
      if (!_spin.isAnimating) _spin.repeat();
      return;
    }
    _spin.reset();
  }

  (Color, Color) _colors(ColorScheme scheme) => switch (widget.kind) {
    StepKind.customer => (scheme.tertiary, scheme.onTertiary),
    StepKind.payment => (scheme.secondary, scheme.onSecondary),
    StepKind.warehouse || StepKind.shipping => (scheme.primary, scheme.onPrimary),
  };

  double _morphTarget() {
    if (widget.active) return 1;
    return 0;
  }

  Duration _morphDuration() {
    if (_reduceMotion) return Duration.zero;
    return const Duration(milliseconds: 500);
  }
}

/// Paints a scalloped round shape per step kind, morphed towards a burst by [burst].
class _StepShapePainter extends CustomPainter {
  const _StepShapePainter({required this.kind, required this.burst, required this.color});

  final StepKind kind;
  final double burst;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final (lobes, depth) = _outline();
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final path = Path();
    const samples = 180;
    for (var i = 0; i <= samples; i++) {
      final angle = 2 * math.pi * i / samples - math.pi / 2;
      final shape = _radius(angle, lobes, depth);
      final burstShape = _radius(angle, 10, 0.14);
      final r = radius * (shape + (burstShape - shape) * burst);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  /// Number of lobes and their depth of the kind's resting shape.
  (int, double) _outline() => switch (kind) {
    StepKind.customer => (9, 0.08),
    StepKind.payment => (4, 0.22),
    StepKind.warehouse => (4, 0.08),
    StepKind.shipping => (8, 0.07),
  };

  /// Radius of a shape with [lobes] lobes of [depth] at [angle], at most 1.
  double _radius(double angle, int lobes, double depth) =>
      (1 + depth * math.cos(lobes * (angle + math.pi / 2))) / (1 + depth);

  @override
  bool shouldRepaint(_StepShapePainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.burst != burst || oldDelegate.color != color;
}
