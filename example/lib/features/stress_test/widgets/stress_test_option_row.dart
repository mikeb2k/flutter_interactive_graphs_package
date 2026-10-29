import 'package:material_ui/material_ui.dart';

/// A labelled row of controls that wraps onto further lines on narrow screens.
class StressTestOptionRow extends StatelessWidget {
  /// Creates the row.
  const StressTestOptionRow({super.key, required this.label, required this.children});

  /// Leading label, e.g. "Nodes:".
  final String label;

  /// The controls.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: style),
          ...children,
        ],
      ),
    );
  }
}
