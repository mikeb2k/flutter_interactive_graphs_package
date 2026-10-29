import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:material_ui/material_ui.dart';

/// Edge anchor on the border of a step card, drawn as a dot while an edge uses it.
class PortDot extends StatelessWidget {
  /// Creates the anchor [id].
  const PortDot({super.key, required this.id, required this.visible});

  /// Anchor id, the side of the card.
  final String id;

  /// Whether an edge is attached, which shows the dot.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GraphAnchor(
      id: id,
      child: AnimatedOpacity(
        opacity: _opacity(),
        duration: _duration(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outline, width: 2),
          ),
          child: const SizedBox.square(dimension: 10),
        ),
      ),
    );
  }

  double _opacity() {
    if (visible) return 1;
    return 0;
  }

  Duration _duration(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return const Duration(milliseconds: 200);
  }
}
