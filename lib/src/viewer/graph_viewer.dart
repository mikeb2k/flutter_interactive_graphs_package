import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:interactive_graphs/src/edges/edge_endpoints.dart';
import 'package:interactive_graphs/src/edges/edge_style.dart';
import 'package:interactive_graphs/src/model/graph.dart';
import 'package:interactive_graphs/src/model/graph_bounds.dart';
import 'package:interactive_graphs/src/model/graph_edge.dart';
import 'package:interactive_graphs/src/theme/graph_theme.dart';
import 'package:interactive_graphs/src/viewer/edge_widgets.dart';
import 'package:interactive_graphs/src/viewer/graph_interaction.dart';
import 'package:interactive_graphs/src/viewer/graph_viewer_config.dart';
import 'package:interactive_graphs/src/viewer/graph_viewer_controller.dart';
import 'package:interactive_graphs/src/viewer/layout_transition.dart';
import 'package:interactive_graphs/src/viewer/node_layer.dart';
import 'package:interactive_graphs/src/viewer/registries.dart';

/// Interactive viewer for a directed graph: pan, zoom, animated layout changes, and optional node
/// selection, hover and drag, edge selection and hover.
///
/// Nodes are widgets from [nodeBuilder]. Nodes without a fixed size are measured with unbounded
/// constraints (give them an intrinsic size) and the graph is laid out again when their sizes
/// change. Edges are either widgets from [edgeBuilder] (labels, any custom painting) or, when it is
/// `null`, painted from one canvas with the [edgeStyle] of each edge, which scales to large graphs.
///
/// ```dart
/// GraphViewer(
///   controller: controller,
///   nodeBuilder: (context, details) => Chip(label: Text(details.node.id)),
///   edgeBuilder: (context, details) => StyledEdge(details: details, label: details.edge.id),
/// )
/// ```
///
/// The viewer fills its constraints, which must be bounded.
class GraphViewer extends StatefulWidget {
  /// Creates a viewer.
  const GraphViewer({
    super.key,
    required this.controller,
    required this.nodeBuilder,
    this.edgeBuilder,
    this.edgeStyle,
    this.config = const GraphViewerConfig(),
    this.callbacks = const GraphInteractionCallbacks(),
  });

  /// State of the viewer.
  final GraphViewerController controller;

  /// Builds the widget of each node.
  final GraphNodeBuilder nodeBuilder;

  /// Builds the widget of each edge; takes precedence over [edgeStyle].
  final GraphEdgeBuilder? edgeBuilder;

  /// Style of each edge in the batched edge layer, used when [edgeBuilder] is `null`. Defaults to
  /// [EdgeStyle.styled] with the [GraphTheme] colors.
  final EdgeStyleBuilder? edgeStyle;

  /// Behavior and look of the viewer.
  final GraphViewerConfig config;

  /// What the viewer reports back.
  final GraphInteractionCallbacks callbacks;

  @override
  State<GraphViewer> createState() => _GraphViewerState();
}

class _GraphViewerState extends State<GraphViewer> with TickerProviderStateMixin {
  late final LayoutTransition _transition = LayoutTransition(this);
  final AnchorRegistry _anchors = AnchorRegistry();
  final EdgeHitRegistry _hits = EdgeHitRegistry();
  late Listenable _positions;
  late Listenable _edgeInputs;
  late final Ticker _transformTicker = createTicker(_onTransformTick);

  Graph? _shownGraph;
  Map<String, Offset> _targets = const {};
  Map<String, EdgeBend> _bends = const {};
  bool _initialSnapDone = false;
  bool _reduceMotion = false;
  Size _viewport = Size.zero;

  TransformAnimationRequest? _request;
  SpringSimulation? _scaleSimulation;
  SpringSimulation? _offsetXSimulation;
  SpringSimulation? _offsetYSimulation;
  double _transformElapsed = 0;

  Offset _gestureFocal = Offset.zero;
  double _gestureScale = 1;
  final Map<int, Offset> _downPositions = {};

  GraphViewerController get _controller => widget.controller;

  bool get _edgesInteractive =>
      widget.config.edgeSelectionMode != SelectionMode.none ||
      widget.config.edgeHoverEnabled ||
      widget.callbacks.onEdgeTap != null;

  @override
  void initState() {
    super.initState();
    _subscribe(_controller);
    _controller.attachConfig(widget.config);
    _initialSnapDone = _controller.hasFittedInitially;
    _onStructureChanged();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  @override
  void didUpdateWidget(GraphViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, _controller)) {
      _unsubscribe(oldWidget.controller);
      _subscribe(_controller);
      _shownGraph = null;
      _initialSnapDone = _controller.hasFittedInitially;
      _onStructureChanged();
    }
    _controller.attachConfig(widget.config);
    if (oldWidget.config.hoverEnabled && !widget.config.hoverEnabled) _controller.interaction.hoveredNodeId = null;
    if (oldWidget.config.edgeHoverEnabled && !widget.config.edgeHoverEnabled) {
      _controller.interaction.hoveredEdgeId = null;
    }
  }

  @override
  void dispose() {
    _unsubscribe(_controller);
    _transformTicker.dispose();
    _transition.dispose();
    _anchors.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(constraints.hasBoundedWidth && constraints.hasBoundedHeight, 'GraphViewer needs bounded constraints.');
        _viewport = constraints.biggest;
        _controller.reportCanvasSize(_viewport);
        return ClipRect(
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerEnd,
            onPointerCancel: _onPointerEnd,
            onPointerSignal: _onPointerSignal,
            child: MouseRegion(
              onHover: _onHover,
              onExit: _onExit,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _onTapUp,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                child: AnimatedOpacity(
                  opacity: _contentOpacity(),
                  duration: widget.config.enterDuration,
                  child: ValueListenableBuilder<GraphTransform>(
                    valueListenable: _controller.transformListenable,
                    builder: _transformed,
                    child: _content(context),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _transformed(BuildContext context, GraphTransform transform, Widget? child) {
    final matrix = Matrix4.translationValues(transform.offset.dx, transform.offset.dy, 0)
      ..multiply(Matrix4.diagonal3Values(transform.scale, transform.scale, 1));
    return Transform(transform: matrix, alignment: Alignment.center, child: child);
  }

  Widget _content(BuildContext context) {
    final graph = _controller.layoutedGraph;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        IgnorePointer(child: _edgeLayer()),
        if (widget.config.showDebugBounds)
          IgnorePointer(
            child: CustomPaint(
              painter: _DebugBoundsPainter(
                bounds: GraphBounds.ofNodes(graph.nodes.values).shift(_layerOrigin()),
                theme: GraphTheme.of(context),
              ),
            ),
          ),
        NodeLayer(
          centerOf: _nodeCenter,
          positions: _positions,
          onMeasured: _controller.reportMeasuredSizes,
          children: [
            for (final node in graph.nodes.values)
              NodeSlot(
                key: ValueKey(node.id),
                nodeId: node.id,
                fixedSize: _controller.graph.nodes[node.id]?.size,
                child: NodeHost(
                  node: node,
                  fixedSize: _controller.graph.nodes[node.id]?.size,
                  controller: _controller,
                  anchors: _anchors,
                  config: widget.config,
                  callbacks: widget.callbacks,
                  builder: widget.nodeBuilder,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _edgeLayer() {
    final builder = widget.edgeBuilder;
    if (builder != null) {
      return ListenableBuilder(listenable: _edgeInputs, builder: (context, _) => _builtEdges(context, builder));
    }
    return CustomPaint(
      painter: _BatchedEdgePainter(
        repaint: _edgeInputs,
        state: this,
        style: widget.edgeStyle ?? _defaultEdgeStyle(GraphTheme.of(context)),
      ),
    );
  }

  Widget _builtEdges(BuildContext context, GraphEdgeBuilder builder) {
    final registry = _hitRegistry();
    final children = <Widget>[];
    for (final edge in _controller.layoutedGraph.edges) {
      final details = _edgeDetails(edge);
      if (details == null) continue;
      children.add(
        EdgeHitScope(
          key: ValueKey(edge.id),
          edgeId: edge.id,
          registry: registry,
          child: Builder(builder: (context) => builder(context, details)),
        ),
      );
    }
    return Stack(fit: StackFit.expand, clipBehavior: Clip.none, children: children);
  }

  EdgeHitRegistry? _hitRegistry() {
    if (_edgesInteractive) return _hits;
    return null;
  }

  double _contentOpacity() {
    if (_controller.hasFittedInitially || _controller.layoutedGraph.nodes.isEmpty) return 1;
    return 0;
  }

  EdgeStyleBuilder _defaultEdgeStyle(GraphThemeData theme) =>
      (details) => EdgeStyle.styled(details.edge, baseColor: theme.edgeColor, backEdgeColor: theme.backEdgeColor);

  // ---- Geometry ---------------------------------------------------------------------------------

  /// Where graph-center-relative positions are measured from in the (untransformed) layer.
  Offset _layerOrigin() => _viewport.center(Offset.zero) - _controller.graphCenter;

  Offset _nodeCenter(String id) =>
      _viewport.center(Offset.zero) + _transition.positionOf(id, _targets) + _controller.interaction.dragOffsetOf(id);

  EdgeDetails? _edgeDetails(GraphEdge edge) {
    final graph = _controller.layoutedGraph;
    final fromNode = graph.nodes[edge.fromId];
    final toNode = graph.nodes[edge.toId];
    if (fromNode == null || toNode == null) return null;
    final bend = _bends[edge.id];
    final (from, to) = EdgeEndpoints.resolve(
      edge: edge,
      bend: bend,
      fromCenter: _nodeCenter(edge.fromId),
      fromSize: fromNode.size,
      toCenter: _nodeCenter(edge.toId),
      toSize: toNode.size,
      fromAnchorOffset: _anchorOffset(edge.fromId, edge.fromAnchor),
      toAnchorOffset: _anchorOffset(edge.toId, edge.toAnchor),
    );
    final interaction = _controller.interaction;
    return EdgeDetails(
      edge: edge,
      from: from,
      to: to,
      bend: bend?.amount,
      isSelected: interaction.isEdgeSelected(edge.id),
      isHovered: interaction.hoveredEdgeId == edge.id,
    );
  }

  /// [details] with endpoints recomputed without the parallel-edge bend, for shapes that don't fan
  /// out.
  EdgeDetails _unbent(EdgeDetails details) {
    final edge = details.edge;
    final graph = _controller.layoutedGraph;
    final (from, to) = EdgeEndpoints.resolve(
      edge: edge,
      fromCenter: _nodeCenter(edge.fromId),
      fromSize: graph.nodes[edge.fromId]?.size,
      toCenter: _nodeCenter(edge.toId),
      toSize: graph.nodes[edge.toId]?.size,
      fromAnchorOffset: _anchorOffset(edge.fromId, edge.fromAnchor),
      toAnchorOffset: _anchorOffset(edge.toId, edge.toAnchor),
    );
    return EdgeDetails(
      edge: edge,
      from: from,
      to: to,
      isSelected: details.isSelected,
      isHovered: details.isHovered,
    );
  }

  Offset? _anchorOffset(String nodeId, String? anchorId) {
    if (anchorId == null) return null;
    return _anchors.offsetOf(nodeId, anchorId);
  }

  String? _edgeAt(Offset viewportPoint) {
    final transform = _controller.transform;
    final center = _viewport.center(Offset.zero);
    final layerPoint = (viewportPoint - center - transform.offset) / transform.scale + center;
    return _hits.hitTest(layerPoint, widget.config.edgeHitTolerance / transform.scale);
  }

  // ---- Controller wiring ------------------------------------------------------------------------

  void _subscribe(GraphViewerController controller) {
    controller.structureListenable.addListener(_onStructureChanged);
    controller.animationListenable.addListener(_onAnimationRequest);
    _positions = Listenable.merge([_transition, controller.interaction.dragOffset]);
    _edgeInputs = Listenable.merge([_transition, controller.interaction, controller.interaction.dragOffset, _anchors]);
  }

  void _unsubscribe(GraphViewerController controller) {
    controller.structureListenable.removeListener(_onStructureChanged);
    controller.animationListenable.removeListener(_onAnimationRequest);
  }

  void _onStructureChanged() {
    final graph = _controller.layoutedGraph;
    if (!identical(graph, _shownGraph)) {
      _shownGraph = graph;
      final center = _controller.graphCenter;
      _targets = {for (final node in graph.nodes.values) node.id: node.position - center};
      _bends = graph.hasParallelEdges ? ParallelEdges.bends(graph.edges) : const {};
      final nodeIds = graph.nodes.keys.toSet();
      _anchors.retain(nodeIds);
      _hits.retain({for (final edge in graph.edges) edge.id});
      _transition.animateTo(_targets, spring: _layoutSpring(graph));
      if (_controller.hasFittedInitially) _initialSnapDone = true;
    }
    if (mounted) setState(() {});
  }

  SpringDescription? _layoutSpring(Graph graph) {
    final skipInitial = !_initialSnapDone && !widget.config.animateInitialPlacement;
    if (!widget.config.animateLayout || skipInitial || _reduceMotion || _controller.isManualLayout(graph)) {
      return null;
    }
    return widget.config.layoutSpring;
  }

  void _onAnimationRequest() {
    final request = _controller.animationListenable.value;
    if (request == null) {
      _transformTicker.stop();
      _request = null;
      return;
    }
    if (_reduceMotion) {
      _controller.applyAnimationFrame(request, request.target);
      _controller.completeAnimation(request);
      return;
    }
    final spring = widget.config.transformSpring;
    final current = _controller.transform;
    final target = request.target;
    final t = _transformElapsed;
    final running = _transformTicker.isActive;
    _scaleSimulation = SpringSimulation(
      spring,
      current.scale,
      target.scale,
      _velocity(_scaleSimulation, t, running),
      tolerance: const Tolerance(distance: 0.0005, velocity: 0.001),
    );
    _offsetXSimulation = SpringSimulation(
      spring,
      current.offset.dx,
      target.offset.dx,
      _velocity(_offsetXSimulation, t, running),
      tolerance: const Tolerance(distance: 0.25, velocity: 1),
    );
    _offsetYSimulation = SpringSimulation(
      spring,
      current.offset.dy,
      target.offset.dy,
      _velocity(_offsetYSimulation, t, running),
      tolerance: const Tolerance(distance: 0.25, velocity: 1),
    );
    _request = request;
    _transformElapsed = 0;
    _transformTicker
      ..stop()
      ..start();
  }

  double _velocity(SpringSimulation? simulation, double time, bool running) {
    if (!running || simulation == null) return 0;
    return simulation.dx(time);
  }

  void _onTransformTick(Duration elapsed) {
    final request = _request;
    final scale = _scaleSimulation;
    final x = _offsetXSimulation;
    final y = _offsetYSimulation;
    if (request == null || scale == null || x == null || y == null) return;
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _transformElapsed = t;
    final done = scale.isDone(t) && x.isDone(t) && y.isDone(t);
    if (done) {
      _controller.applyAnimationFrame(request, request.target);
      _controller.completeAnimation(request);
      _transformTicker.stop();
      return;
    }
    _controller.applyAnimationFrame(request, GraphTransform(scale.x(t), Offset(x.x(t), y.x(t))));
  }

  // ---- Gestures ---------------------------------------------------------------------------------

  void _onPointerDown(PointerDownEvent event) => _downPositions[event.pointer] = event.localPosition;

  void _onPointerEnd(PointerEvent event) => _downPositions.remove(event.pointer);

  void _onScaleStart(ScaleStartDetails details) {
    // Start from where the fingers went down, so the movement within the touch slop pans too
    final downs = _downPositions.values;
    _gestureFocal = details.localFocalPoint;
    if (downs.isNotEmpty && downs.length == details.pointerCount) {
      _gestureFocal = downs.reduce((a, b) => a + b) / downs.length.toDouble();
    }
    _gestureScale = 1;
    // A gesture takes over from any running animation
    _controller.updateTransform();
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final factor = _gestureScale == 0 ? 1.0 : details.scale / _gestureScale;
    _controller.applyGesture(
      focalPoint: _gestureFocal,
      pan: details.localFocalPoint - _gestureFocal,
      factor: factor,
    );
    _gestureFocal = details.localFocalPoint;
    _gestureScale = details.scale;
  }

  void _onTapUp(TapUpDetails details) {
    final config = widget.config;
    final onEdgeTap = widget.callbacks.onEdgeTap;
    final edgeId = _edgesInteractive ? _edgeAt(details.localPosition) : null;
    final edge = edgeId == null ? null : _controller.layoutedGraph.edge(edgeId);
    if (edge != null && (config.edgeSelectionMode != SelectionMode.none || onEdgeTap != null)) {
      _controller.interaction.tapEdge(edge.id, config.edgeSelectionMode);
      onEdgeTap?.call(edge);
      return;
    }
    _controller.interaction.tapCanvas(config.selectionMode, config.edgeSelectionMode);
    widget.callbacks.onCanvasTap?.call();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    switch (event) {
      case PointerScrollEvent():
        GestureBinding.instance.pointerSignalResolver.register(event, _onScroll);
      case PointerScaleEvent(:final scale, :final localPosition):
        GestureBinding.instance.pointerSignalResolver.register(
          event,
          (_) => _controller.applyGesture(focalPoint: localPosition, factor: scale),
        );
      default:
        break;
    }
  }

  void _onScroll(PointerSignalEvent signal) {
    final event = signal as PointerScrollEvent;
    final config = widget.config;
    if (config.scrollZoomCondition(event)) {
      _controller.applyGesture(
        focalPoint: event.localPosition,
        factor: math.exp(-event.scrollDelta.dy * config.scrollZoomSpeed),
      );
    } else {
      _controller.applyGesture(pan: -event.scrollDelta * config.scrollPanSpeed);
    }
  }

  void _onHover(PointerHoverEvent event) {
    if (!widget.config.edgeHoverEnabled) return;
    final interaction = _controller.interaction;
    // Nodes are drawn over edges
    interaction.hoveredEdgeId = interaction.hoveredNodeId == null ? _edgeAt(event.localPosition) : null;
  }

  void _onExit(PointerExitEvent event) {
    if (widget.config.edgeHoverEnabled) _controller.interaction.hoveredEdgeId = null;
  }
}

/// Paints every edge from one canvas.
class _BatchedEdgePainter extends CustomPainter {
  _BatchedEdgePainter({required Listenable repaint, required this.state, required this.style})
    : super(repaint: repaint);

  final _GraphViewerState state;
  final EdgeStyleBuilder style;

  @override
  void paint(Canvas canvas, Size size) {
    final hits = state._hitRegistry();
    for (final edge in state._controller.layoutedGraph.edges) {
      var details = state._edgeDetails(edge);
      if (details == null) continue;
      var edgeStyle = style(details);
      if (details.bend != null && !edge.isSelfLoop && !edgeStyle.shape.fansOut) {
        details = state._unbent(details);
        edgeStyle = style(details);
      }
      final bend = details.bend;
      final path = edgeStyle.createPath(edge, bend, details.from, details.to);
      hits?.report(edge.id, path);
      EdgePainting.paint(canvas, path, edgeStyle);
    }
  }

  @override
  bool shouldRepaint(_BatchedEdgePainter oldDelegate) => true;

  @override
  bool? hitTest(Offset position) => false;
}

/// Outlines the graph bounds and the viewport.
class _DebugBoundsPainter extends CustomPainter {
  const _DebugBoundsPainter({required this.bounds, required this.theme});

  final Rect bounds;
  final GraphThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..drawRect(
        bounds,
        Paint()
          ..color = theme.debugGraphBoundsColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      )
      ..drawRect(
        Offset.zero & size,
        Paint()
          ..color = theme.debugViewportColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
  }

  @override
  bool shouldRepaint(_DebugBoundsPainter oldDelegate) => oldDelegate.bounds != bounds || oldDelegate.theme != theme;
}
