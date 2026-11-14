import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_copy.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_defaults.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_ports.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_state.dart';
import 'package:interactive_graphs_example/features/playground/providers/playground_provider.dart';
import 'package:interactive_graphs_example/features/playground/widgets/connection_mode_banner.dart';
import 'package:interactive_graphs_example/features/playground/widgets/edge_creation_form.dart';
import 'package:interactive_graphs_example/features/playground/widgets/graph_keyboard_controls.dart';
import 'package:interactive_graphs_example/features/playground/widgets/node_creation_form.dart';
import 'package:interactive_graphs_example/features/playground/widgets/playground_controls_bar.dart';
import 'package:interactive_graphs_example/features/playground/widgets/playground_edge.dart';
import 'package:interactive_graphs_example/features/playground/widgets/playground_node.dart';
import 'package:interactive_graphs_example/features/playground/widgets/playground_toolbar.dart';
import 'package:interactive_graphs_example/features/playground/widgets/playground_zoom_column.dart';
import 'package:interactive_graphs_example/features/playground/widgets/size_reporter.dart';
import 'package:material_ui/material_ui.dart';

/// The editable graph: tap two nodes to connect them, long-press a node to remove it, drag nodes,
/// add nodes and edges with the forms, switch layouts and edge styles, or let it generate a graph.
class PlaygroundView extends ConsumerStatefulWidget {
  /// Creates the screen.
  const PlaygroundView({super.key});

  /// Route to this screen.
  static Route<void> route() => MaterialPageRoute<void>(builder: (_) => const PlaygroundView());

  @override
  ConsumerState<PlaygroundView> createState() => _PlaygroundViewState();
}

class _PlaygroundViewState extends ConsumerState<PlaygroundView> {
  late final GraphViewerController _controller;

  /// Direction until one is picked: vertical when the screen first opens in portrait.
  LayoutDirection? _orientationDirection;

  Timer? _generator;
  bool _generateNodeNext = true;

  Graph? _layoutBeforeRecenter;
  Timer? _recenterTimeout;

  double _overlayHeight = 0;
  double _toolbarHeight = 0;

  @override
  void initState() {
    super.initState();
    final state = ref.read(playgroundProvider);
    _controller = GraphViewerController(graph: state.graph, layoutConfig: state.layoutConfig(_fallbackDirection));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orientationDirection != null) return;
    final size = MediaQuery.sizeOf(context);
    _orientationDirection = _directionForSize(size);
    _controller.layoutConfig = ref.read(playgroundProvider).layoutConfig(_fallbackDirection);
  }

  @override
  void dispose() {
    _generator?.cancel();
    _stopRecenterWait();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playgroundProvider, _onStateChanged);
    final state = ref.watch(playgroundProvider);
    final notifier = ref.read(playgroundProvider.notifier);
    final compact = MediaQuery.sizeOf(context).width < PlaygroundDefaults.compactWidth;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(PlaygroundCopy.title),
            Text(
              PlaygroundCopy.graphSize(state.graph.nodes.length, state.graph.edges.length),
              style: textTheme.bodySmall,
            ),
          ],
        ),
        bottom: PlaygroundControlsBar(
          controller: _controller,
          layoutAlgorithm: state.layoutAlgorithm,
          layoutDirection: state.directionOr(_fallbackDirection),
          edgeStyle: state.edgeStyle,
          showPorts: state.showPorts,
          showDebugBounds: state.showDebugBounds,
          onLayoutAlgorithmChange: notifier.setLayoutAlgorithm,
          onLayoutDirectionChange: notifier.setLayoutDirection,
          onEdgeStyleChange: notifier.setEdgeStyle,
          onTogglePorts: notifier.togglePorts,
          onToggleDebugBounds: notifier.toggleDebugBounds,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: GraphKeyboardControls(
                controller: _controller,
                child: GraphViewer(
                  controller: _controller,
                  config: PlaygroundDefaults.viewerConfig(showDebugBounds: state.showDebugBounds),
                  callbacks: GraphInteractionCallbacks(
                    onNodeTap: _onNodeTap,
                    onNodeLongPress: _onNodeLongPress,
                    onCanvasTap: notifier.cancelConnection,
                  ),
                  nodeBuilder: _node,
                  edgeBuilder: _edge,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizeReporter(
              onSizeChanged: _onOverlaySize,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConnectionModeBanner(
                    visible: state.connection.isActive,
                    sourceNodeLabel: _sourceLabel(state),
                    onCancel: notifier.cancelConnection,
                  ),
                  NodeCreationForm(
                    visible: state.showNodeForm,
                    newNodeLabel: state.newNodeLabel,
                    selectedColorType: state.newNodeColor,
                    onNodeLabelChange: notifier.setNewNodeLabel,
                    onColorTypeSelect: notifier.setNewNodeColor,
                    onCreateNode: _createNode,
                  ),
                  EdgeCreationForm(
                    visible: state.showEdgeForm,
                    hasNodes: state.graph.nodes.isNotEmpty,
                    fromNodeLabel: state.fromNodeLabel,
                    toNodeLabel: state.toNodeLabel,
                    onFromNodeLabelChange: notifier.setFromNodeLabel,
                    onToNodeLabelChange: notifier.setToNodeLabel,
                    edgeLabel: state.newEdgeLabel,
                    onEdgeLabelChange: notifier.setNewEdgeLabel,
                    labelPosition: state.newEdgeLabelPosition,
                    onLabelPositionChange: notifier.setNewEdgeLabelPosition,
                    onCreateEdge: _createEdge,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 12,
                  children: [
                    ?_zoomColumn(compact),
                    Center(
                      child: SizeReporter(
                        onSizeChanged: _onToolbarSize,
                        child: PlaygroundToolbar(
                          controller: _controller,
                          isAutoGenerating: state.isAutoGenerating,
                          showZoomControls: !compact,
                          onAddNode: notifier.toggleNodeForm,
                          onAddEdge: notifier.toggleEdgeForm,
                          onToggleGenerating: notifier.toggleAutoGenerating,
                          onClear: notifier.clearGraph,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LayoutDirection get _fallbackDirection => _orientationDirection ?? LayoutDirection.horizontal;

  LayoutDirection _directionForSize(Size size) {
    if (size.width < size.height) return LayoutDirection.vertical;
    return LayoutDirection.horizontal;
  }

  Widget? _zoomColumn(bool compact) {
    if (!compact) return null;
    return PlaygroundZoomColumn(onZoomIn: _controller.zoomIn, onZoomOut: _controller.zoomOut);
  }

  String _sourceLabel(PlaygroundState state) {
    final sourceId = state.connection.sourceNodeId;
    if (sourceId == null) return '';
    return state.nodeData[sourceId]?.label ?? '';
  }

  Widget _node(BuildContext context, NodeDetails details) {
    final state = ref.read(playgroundProvider);
    final data = state.nodeData[details.node.id];
    if (data == null) return const SizedBox.shrink();
    return PlaygroundNode(
      data: data,
      ports: state.graph.portsOf(details.node.id, vertical: state.isVertical(_fallbackDirection)),
      isSelected: details.isSelected,
      isHighlighted: details.isHovered || details.isDragging,
    );
  }

  Widget _edge(BuildContext context, EdgeDetails details) {
    final state = ref.read(playgroundProvider);
    return PlaygroundEdge(details: details, style: state.edgeStyle, data: state.edgeData[details.edge.id]);
  }

  // ---- State to controller ----------------------------------------------------------------------

  void _onStateChanged(PlaygroundState? previous, PlaygroundState next) {
    _controller.updateGraph(next.graph);
    final config = next.layoutConfig(_fallbackDirection);
    if (config != _controller.layoutConfig) {
      _controller.layoutConfig = config;
      _recenterWhenLaidOut();
    }
    _syncGenerator(next.isAutoGenerating);
  }

  /// Recenters once the newly picked layout lands, or after a timeout.
  void _recenterWhenLaidOut() {
    _stopRecenterWait();
    _layoutBeforeRecenter = _controller.layoutedGraph;
    _controller.addListener(_checkLayoutLanded);
    _recenterTimeout = Timer(PlaygroundDefaults.recenterTimeout, _recenter);
  }

  void _checkLayoutLanded() {
    if (!identical(_controller.layoutedGraph, _layoutBeforeRecenter)) _recenter();
  }

  void _recenter() {
    _stopRecenterWait();
    if (mounted) _controller.centerGraph();
  }

  void _stopRecenterWait() {
    _recenterTimeout?.cancel();
    _recenterTimeout = null;
    if (_layoutBeforeRecenter != null) _controller.removeListener(_checkLayoutLanded);
    _layoutBeforeRecenter = null;
  }

  /// Alternates between adding a node and connecting two random nodes while generating.
  void _syncGenerator(bool generating) {
    if (generating && _generator == null) {
      _generateNodeNext = true;
      _generator = Timer.periodic(PlaygroundDefaults.generateInterval, _onGenerateTick);
    } else if (!generating) {
      _generator?.cancel();
      _generator = null;
    }
  }

  void _onGenerateTick(Timer timer) {
    ref.read(playgroundProvider.notifier).autoGenerateStep(addNode: _generateNodeNext);
    _generateNodeNext = !_generateNodeNext;
  }

  /// Centers the graph in the area between the overlays and the toolbar.
  void _onOverlaySize(Size size) {
    _overlayHeight = size.height;
    _updateContentInsets();
  }

  void _onToolbarSize(Size size) {
    _toolbarHeight = size.height + 16;
    _updateContentInsets();
  }

  void _updateContentInsets() =>
      _controller.updateContentInsets(EdgeInsets.only(top: _overlayHeight, bottom: _toolbarHeight));

  // ---- User actions -----------------------------------------------------------------------------

  void _onNodeTap(GraphNode node) => ref.read(playgroundProvider.notifier).tapNode(node.id);

  void _onNodeLongPress(GraphNode node) => ref.read(playgroundProvider.notifier).removeNode(node.id);

  void _createNode() {
    final state = ref.read(playgroundProvider);
    final typed = state.newNodeLabel.trim();
    if (ref.read(playgroundProvider.notifier).createNodeFromForm()) return;
    _showMessage(PlaygroundCopy.duplicateNode(_labelOrDefault(typed, state)));
  }

  String _labelOrDefault(String typed, PlaygroundState state) {
    if (typed.isNotEmpty) return typed;
    return PlaygroundCopy.defaultNodeLabel('${state.nextNodeId}');
  }

  void _createEdge() {
    if (ref.read(playgroundProvider.notifier).createEdgeFromForm()) return;
    _showMessage(PlaygroundCopy.unknownNodes);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }
}
