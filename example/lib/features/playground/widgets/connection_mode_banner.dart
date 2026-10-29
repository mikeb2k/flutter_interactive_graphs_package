import 'package:interactive_graphs_example/features/playground/models/playground_copy.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_defaults.dart';
import 'package:material_ui/material_ui.dart';

/// Tells the user that the next tapped node gets an edge from [sourceNodeLabel]; expands while
/// [visible].
class ConnectionModeBanner extends StatelessWidget {
  /// Creates the banner.
  const ConnectionModeBanner({
    super.key,
    required this.visible,
    required this.sourceNodeLabel,
    required this.onCancel,
  });

  /// Whether connect mode is on.
  final bool visible;

  /// Label of the source node.
  final String sourceNodeLabel;

  /// Leaves connect mode.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: PlaygroundDefaults.panelDurationOf(context),
      alignment: Alignment.topCenter,
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    if (!visible) return const SizedBox(width: double.infinity);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: scheme.tertiaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                PlaygroundCopy.connectFrom(sourceNodeLabel),
                style: textTheme.titleSmall?.copyWith(color: scheme.onTertiaryContainer),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(foregroundColor: scheme.onTertiaryContainer),
              child: const Text(PlaygroundCopy.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
