import 'package:material_ui/material_ui.dart';

/// One tracking event of an expanded step: a dot, the time and the text. Events reached so far
/// are filled in.
class StepEventRow extends StatelessWidget {
  /// Creates an event row.
  const StepEventRow({super.key, required this.time, required this.text, required this.reached, required this.color});

  /// When the event happened.
  final String time;

  /// What happened.
  final String text;

  /// Whether the order got this far.
  final bool reached;

  /// Content color of the card.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: _dotAlpha()),
            shape: BoxShape.circle,
          ),
          child: const SizedBox.square(dimension: 8),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: SizedBox(
            width: 48,
            child: Text(
              time,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.7)),
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: color.withValues(alpha: _textAlpha())),
          ),
        ),
      ],
    );
  }

  double _dotAlpha() {
    if (reached) return 1;
    return 0.25;
  }

  double _textAlpha() {
    if (reached) return 1;
    return 0.6;
  }
}
