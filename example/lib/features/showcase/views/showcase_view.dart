import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:material_ui/material_ui.dart';

/// Temporary smoke screen; replaced by the showcase port.
class ShowcaseView extends StatefulWidget {
  /// Creates the screen.
  const ShowcaseView({super.key});

  @override
  State<ShowcaseView> createState() => _ShowcaseViewState();
}

class _ShowcaseViewState extends State<ShowcaseView> {
  late final GraphViewerController _controller = GraphViewerController(
    graph: Graph.build(
      (g) => g
        ..nodes(['order', 'payment', 'stock', 'receipt', 'pack', 'hub', 'courier', 'delivered'])
        ..edges([
          ('order', 'payment'),
          ('order', 'stock'),
          ('payment', 'receipt'),
          ('stock', 'pack'),
          ('pack', 'hub'),
          ('hub', 'courier'),
          ('courier', 'delivered'),
          ('courier', 'hub'),
          ('courier', 'courier'),
        ])
        ..edge('payment', 'pack', id: 'p2')
        ..edge('payment', 'pack', id: 'p3'),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: GraphViewer(
        controller: _controller,
        config: const GraphViewerConfig(
          selectionMode: SelectionMode.single,
          nodeDragEnabled: true,
          hoverEnabled: true,
          edgeSelectionMode: SelectionMode.single,
          edgeHoverEnabled: true,
        ),
        nodeBuilder: (context, details) => Card(
          color: details.isSelected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          child: Padding(padding: const EdgeInsets.all(16), child: Text(details.node.id)),
        ),
        edgeBuilder: (context, details) =>
            StyledEdge(details: details, label: details.edge.id, strokeWidth: details.isHovered ? 5 : 2),
      ),
    );
  }
}
