import 'package:interactive_graphs_example/features/playground/models/playground_copy.dart';
import 'package:interactive_graphs_example/models/node_data.dart';
import 'package:interactive_graphs_example/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A color choice of the node form: one node color, or a gradient of all of them for a random
/// color when [colorType] is `null`. The selected one shows a check mark and a ring.
class NodeColorSwatch extends StatelessWidget {
  /// Creates a swatch.
  const NodeColorSwatch({super.key, required this.colorType, required this.selected, required this.onTap});

  /// The color, `null` for random.
  final NodeColorType? colorType;

  /// Whether this choice is picked.
  final bool selected;

  /// Picks this choice.
  final VoidCallback onTap;

  /// Visible size of the swatch; the tap target is 48.
  static const double swatchSize = 32;

  @override
  Widget build(BuildContext context) {
    final palette = NodePalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: _name(),
      child: Semantics(
        button: true,
        selected: selected,
        label: _name(),
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox.square(
            dimension: kMinInteractiveDimension,
            child: Center(
              child: Container(
                width: swatchSize,
                height: swatchSize,
                decoration: BoxDecoration(
                  color: _fill(palette),
                  gradient: _gradient(palette),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _ringColor(scheme), width: 2),
                ),
                child: _check(palette),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _name() {
    final type = colorType;
    if (type == null) return PlaygroundCopy.randomColor;
    return PlaygroundCopy.nodeColor(type);
  }

  Color? _fill(NodePalette palette) => colorType?.fill(palette);

  Gradient? _gradient(NodePalette palette) {
    if (colorType != null) return null;
    return LinearGradient(colors: [for (final type in NodeColorType.values) type.fill(palette)]);
  }

  Color _ringColor(ColorScheme scheme) {
    if (selected) return scheme.onSurface;
    return scheme.onSurface.withValues(alpha: 0);
  }

  Widget? _check(NodePalette palette) {
    if (!selected) return null;
    final onColor = (colorType ?? NodeColorType.blue).onFill(palette);
    return Icon(Icons.check, size: 18, color: onColor);
  }
}
