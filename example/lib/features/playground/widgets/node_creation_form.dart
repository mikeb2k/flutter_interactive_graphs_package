import 'package:interactive_graphs_example/features/playground/models/playground_copy.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_defaults.dart';
import 'package:interactive_graphs_example/features/playground/widgets/node_color_swatch.dart';
import 'package:interactive_graphs_example/models/node_data.dart';
import 'package:material_ui/material_ui.dart';

/// Form that adds a node: a label, a color (or random) and a create button. Expands while [visible];
/// the color row moves below the label on narrow screens.
class NodeCreationForm extends StatefulWidget {
  /// Creates the form.
  const NodeCreationForm({
    super.key,
    required this.visible,
    required this.newNodeLabel,
    required this.selectedColorType,
    required this.onNodeLabelChange,
    required this.onColorTypeSelect,
    required this.onCreateNode,
  });

  /// Whether the form is open.
  final bool visible;

  /// Typed label.
  final String newNodeLabel;

  /// Picked color, `null` for random.
  final NodeColorType? selectedColorType;

  /// Label edits.
  final ValueChanged<String> onNodeLabelChange;

  /// Color picks, `null` for random.
  final ValueChanged<NodeColorType?> onColorTypeSelect;

  /// Creates the node.
  final VoidCallback onCreateNode;

  /// Below this width the colors go on a row of their own.
  static const double wrapWidth = 560;

  @override
  State<NodeCreationForm> createState() => _NodeCreationFormState();
}

class _NodeCreationFormState extends State<NodeCreationForm> {
  late final TextEditingController _label = TextEditingController(text: widget.newNodeLabel);

  @override
  void didUpdateWidget(NodeCreationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_label.text != widget.newNodeLabel) _label.text = widget.newNodeLabel;
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: PlaygroundDefaults.panelDurationOf(context),
      alignment: Alignment.topCenter,
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    if (!widget.visible) return const SizedBox(width: double.infinity);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(builder: _layout),
      ),
    );
  }

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final field = Expanded(
      child: TextField(
        controller: _label,
        onChanged: widget.onNodeLabelChange,
        onSubmitted: _submit,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: PlaygroundCopy.nodeLabel,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
    final create = IconButton.filled(
      onPressed: widget.onCreateNode,
      tooltip: PlaygroundCopy.createNode,
      icon: const Icon(Icons.add),
    );
    final colors = Wrap(
      children: [
        NodeColorSwatch(
          colorType: null,
          selected: widget.selectedColorType == null,
          onTap: () => widget.onColorTypeSelect(null),
        ),
        for (final type in NodeColorType.values)
          NodeColorSwatch(
            colorType: type,
            selected: widget.selectedColorType == type,
            onTap: () => widget.onColorTypeSelect(type),
          ),
      ],
    );
    if (constraints.maxWidth < NodeCreationForm.wrapWidth) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [field, const SizedBox(width: 8), create]),
          colors,
        ],
      );
    }
    return Row(children: [field, const SizedBox(width: 8), colors, const SizedBox(width: 8), create]);
  }

  void _submit(String _) => widget.onCreateNode();
}
