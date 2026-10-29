import 'package:material_ui/material_ui.dart';

/// Label of a showcase edge, in a pill.
class EdgeLabelPill extends StatelessWidget {
  /// Creates the pill.
  const EdgeLabelPill({super.key, required this.label});

  /// The label text.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(color: scheme.secondaryContainer, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSecondaryContainer)),
      ),
    );
  }
}
