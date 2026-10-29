import 'package:interactive_graphs_example/features/showcase/models/showcase_copy.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_spec.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_status.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/step_event_row.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/step_fact.dart';
import 'package:material_ui/material_ui.dart';

/// Status, facts and tracking events of an expanded step.
class StepDetails extends StatelessWidget {
  /// Creates the details of [spec].
  const StepDetails({super.key, required this.spec, required this.status, required this.color});

  /// The step.
  final StepSpec spec;

  /// Its status.
  final StepStatus status;

  /// Content color of the card.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final reached = _reached();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              Expanded(
                flex: 13,
                child: StepFact(label: ShowcaseCopy.statusFact, value: status.label, color: color),
              ),
              for (final (label, value) in spec.facts)
                Expanded(
                  flex: 10,
                  child: StepFact(label: label, value: value, color: color),
                ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              for (final (index, (time, text)) in spec.events.indexed)
                StepEventRow(time: time, text: text, reached: index < reached, color: color),
            ],
          ),
          if (status.isRunning)
            LinearProgressIndicator(
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.all(Radius.circular(2)),
            ),
        ],
      ),
    );
  }

  /// Number of events reached so far.
  int _reached() => switch (status) {
    StepStatus.waiting => 0,
    StepStatus.done => spec.events.length,
    _ => 1,
  };
}
