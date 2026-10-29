import 'package:interactive_graphs_example/features/showcase/models/step_status.dart';
import 'package:material_ui/material_ui.dart';

/// Waiting clock, progress indicator, check mark or error icon of a step.
class StepStatusIcon extends StatelessWidget {
  /// Creates the icon of [status].
  const StepStatusIcon({super.key, required this.status, required this.color});

  /// The status shown.
  final StepStatus status;

  /// Content color of the card.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final duration = _duration(context);
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration * 2 ~/ 3,
      transitionBuilder: _transition,
      child: SizedBox.square(
        key: ValueKey(status),
        dimension: 32,
        child: Center(child: _icon(context)),
      ),
    );
  }

  Widget _transition(Widget child, Animation<double> animation) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(scale: Tween<double>(begin: 0.5, end: 1).animate(animation), child: child),
  );

  Widget _icon(BuildContext context) => switch (status) {
    StepStatus.waiting => Icon(
      Icons.schedule,
      size: 20,
      color: color.withValues(alpha: 0.6),
      semanticLabel: status.label,
    ),
    StepStatus.active || StepStatus.retrying => SizedBox.square(
      dimension: 24,
      child: CircularProgressIndicator(color: color, strokeWidth: 3, semanticsLabel: status.label),
    ),
    StepStatus.done => Icon(Icons.check_circle, size: 24, color: color, semanticLabel: status.label),
    StepStatus.failed => Icon(
      Icons.error,
      size: 24,
      color: Theme.of(context).colorScheme.error,
      semanticLabel: status.label,
    ),
  };

  Duration _duration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return const Duration(milliseconds: 180);
  }
}
