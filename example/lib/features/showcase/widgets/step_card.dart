import 'package:interactive_graphs_example/features/showcase/models/showcase_metrics.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_spec.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_status.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/step_details.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/step_kind_icon.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/step_status_icon.dart';
import 'package:interactive_graphs_example/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Card of one order step: icon, title, subtitle and status. Takes the color of its status, grows
/// to show facts and tracking events when [expanded], and lifts when hovered or dragged.
class StepCard extends StatelessWidget {
  /// Creates the card of [spec].
  const StepCard({
    super.key,
    required this.spec,
    required this.status,
    required this.expanded,
    required this.isSelected,
    required this.isHovered,
    required this.isDragging,
  });

  /// The step.
  final StepSpec spec;

  /// Its status.
  final StepStatus status;

  /// Whether the details are shown.
  final bool expanded;

  /// Whether the viewer has the node selected.
  final bool isSelected;

  /// Whether the pointer is over the node.
  final bool isHovered;

  /// Whether the node is being dragged.
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (container, content) = _colors(scheme, NodePalette.of(context));
    final duration = _duration(context);
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: content),
      duration: duration,
      builder: (context, color, _) {
        final contentColor = color ?? content;
        return AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          width: _width(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: container,
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            boxShadow: _shadows(scheme),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            border: _border(scheme),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  StepKindIcon(kind: spec.kind, icon: spec.icon, active: status.isRunning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          spec.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(color: contentColor, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          spec.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: contentColor.withValues(alpha: 0.72)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StepStatusIcon(status: status, color: contentColor),
                ],
              ),
              _details(contentColor, duration),
            ],
          ),
        );
      },
    );
  }

  /// Facts and events, faded and sized in and out unless motion is reduced.
  Widget _details(Color color, Duration duration) {
    if (duration == Duration.zero) {
      if (!expanded) return const SizedBox.shrink();
      return StepDetails(spec: spec, status: status, color: color);
    }
    return AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity),
      secondChild: StepDetails(spec: spec, status: status, color: color),
      crossFadeState: _crossFadeState(),
      duration: duration,
      sizeCurve: Curves.easeOutCubic,
    );
  }

  /// Container and content color of the status. Finished steps turn green.
  (Color, Color) _colors(ColorScheme scheme, NodePalette palette) => switch (status) {
    StepStatus.waiting => (scheme.surfaceContainerHighest, scheme.onSurface),
    StepStatus.active || StepStatus.retrying => (scheme.primaryContainer, scheme.onPrimaryContainer),
    StepStatus.done => (palette.green, palette.onGreen),
    StepStatus.failed => (scheme.errorContainer, scheme.onErrorContainer),
  };

  double _width() {
    if (expanded) return ShowcaseMetrics.expandedStepWidth;
    return ShowcaseMetrics.stepWidth;
  }

  List<BoxShadow> _shadows(ColorScheme scheme) {
    final elevation = _elevation();
    if (elevation == 0) return const [];
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: 0.24),
        blurRadius: elevation * 2,
        offset: Offset(0, elevation / 2),
      ),
    ];
  }

  double _elevation() {
    if (isDragging) return 8;
    if (isHovered) return 3;
    return 0;
  }

  Border? _border(ColorScheme scheme) {
    if (!isSelected) return null;
    return Border.all(color: scheme.primary, width: 2);
  }

  CrossFadeState _crossFadeState() {
    if (expanded) return CrossFadeState.showSecond;
    return CrossFadeState.showFirst;
  }

  Duration _duration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return const Duration(milliseconds: 300);
  }
}
