import 'package:interactive_graphs_example/features/playground/models/playground_copy.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_defaults.dart';
import 'package:material_ui/material_ui.dart';

/// Form that adds an edge between two nodes named by their labels, with an optional label and its
/// position along the edge. Expands while [visible].
class EdgeCreationForm extends StatefulWidget {
  /// Creates the form.
  const EdgeCreationForm({
    super.key,
    required this.visible,
    required this.hasNodes,
    required this.fromNodeLabel,
    required this.toNodeLabel,
    required this.onFromNodeLabelChange,
    required this.onToNodeLabelChange,
    required this.edgeLabel,
    required this.onEdgeLabelChange,
    required this.labelPosition,
    required this.onLabelPositionChange,
    required this.onCreateEdge,
  });

  /// Whether the form is open.
  final bool visible;

  /// Whether the graph has nodes to connect.
  final bool hasNodes;

  /// Typed start node label.
  final String fromNodeLabel;

  /// Typed end node label.
  final String toNodeLabel;

  /// Start label edits.
  final ValueChanged<String> onFromNodeLabelChange;

  /// End label edits.
  final ValueChanged<String> onToNodeLabelChange;

  /// Typed edge label.
  final String edgeLabel;

  /// Edge label edits.
  final ValueChanged<String> onEdgeLabelChange;

  /// Label position, `0` to `1`.
  final double labelPosition;

  /// Label position changes.
  final ValueChanged<double> onLabelPositionChange;

  /// Creates the edge.
  final VoidCallback onCreateEdge;

  @override
  State<EdgeCreationForm> createState() => _EdgeCreationFormState();
}

class _EdgeCreationFormState extends State<EdgeCreationForm> {
  late final TextEditingController _from = TextEditingController(text: widget.fromNodeLabel);
  late final TextEditingController _to = TextEditingController(text: widget.toNodeLabel);
  late final TextEditingController _label = TextEditingController(text: widget.edgeLabel);

  @override
  void didUpdateWidget(EdgeCreationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(_from, widget.fromNodeLabel);
    _sync(_to, widget.toNodeLabel);
    _sync(_label, widget.edgeLabel);
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
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
      color: Theme.of(context).colorScheme.tertiaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(8), child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (!widget.hasNodes) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          PlaygroundCopy.createNodesFirst,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: scheme.error),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(child: _field(_from, PlaygroundCopy.from, widget.onFromNodeLabelChange)),
            Text(PlaygroundCopy.arrow, style: textTheme.titleMedium?.copyWith(color: scheme.onTertiaryContainer)),
            Expanded(child: _field(_to, PlaygroundCopy.to, widget.onToNodeLabelChange)),
            IconButton.filled(
              onPressed: widget.onCreateEdge,
              tooltip: PlaygroundCopy.createEdge,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        _field(_label, PlaygroundCopy.edgeLabel, widget.onEdgeLabelChange),
        ?_positionSlider(scheme, textTheme),
      ],
    );
  }

  Widget _field(TextEditingController controller, String hint, ValueChanged<String> onChanged) => TextField(
    controller: controller,
    onChanged: onChanged,
    onSubmitted: _submit,
    textInputAction: TextInputAction.done,
    decoration: InputDecoration(
      hintText: hint,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  Widget? _positionSlider(ColorScheme scheme, TextTheme textTheme) {
    if (widget.edgeLabel.trim().isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PlaygroundCopy.labelPosition(widget.labelPosition),
          style: textTheme.labelSmall?.copyWith(color: scheme.onTertiaryContainer),
        ),
        Slider(
          value: widget.labelPosition,
          onChanged: widget.onLabelPositionChange,
          semanticFormatterCallback: PlaygroundCopy.labelPosition,
        ),
      ],
    );
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text != value) controller.text = value;
  }

  void _submit(String _) => widget.onCreateEdge();
}
