import 'package:material_ui/material_ui.dart';

/// One labelled value in the details of an expanded step.
class StepFact extends StatelessWidget {
  /// Creates a fact.
  const StepFact({super.key, required this.label, required this.value, required this.color});

  /// What the value is.
  final String label;

  /// The value.
  final String value;

  /// Content color of the card.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(color: color.withValues(alpha: 0.7)),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
