import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:interactive_graphs/src/layout/graph_layout.dart';
import 'package:interactive_graphs/src/layout/layout_config.dart';
import 'package:interactive_graphs/src/model/graph.dart';
import 'package:interactive_graphs/src/model/graph_bounds.dart';
import 'package:interactive_graphs/src/viewer/graph_interaction.dart';
import 'package:interactive_graphs/src/viewer/graph_viewer_config.dart';

/// Zoom level and pan offset of a viewer.
@immutable
final class GraphTransform {
  /// Creates a transform.
  const GraphTransform(this.scale, this.offset);

  /// The identity transform.
  static const GraphTransform identity = GraphTransform(1, Offset.zero);

  /// Zoom level, unitless.
  final double scale;

  /// Pan offset in screen pixels, applied after scaling about the viewport center.
  final Offset offset;

  @override
  bool operator ==(Object other) => other is GraphTransform && other.scale == scale && other.offset == offset;

  @override
  int get hashCode => Object.hash(scale, offset);

  @override
  String toString() => 'GraphTransform($scale, $offset)';
}

/// A transform the viewer should animate to. Superseded by a newer request or any direct change.
@internal
@immutable
final class TransformAnimationRequest {
  /// Creates a request.
  const TransformAnimationRequest(this.target, this.version);

  /// Where to animate to.
  final GraphTransform target;

  /// Increases with every request.
  final int version;
}

/// State of a `GraphViewer`: the graph, its laid-out copy, the view transform and the
/// [interaction] state.
///
/// The graph is laid out again whenever the graph, the [layoutConfig], the measured node sizes or
/// the canvas change, or on [relayout]. Large graphs (at least [backgroundLayoutThreshold] nodes)
/// are laid out on a background isolate on platforms that have one.
///
/// Coordinates: node positions are in graph space. The viewer puts the center of the node
/// positions at the viewport center, scales by [scale] about it and pans by [offset]:
/// `viewport = viewportCenter + offset + scale * (graphPoint - graphCenter)`. Use
/// [graphToViewport] and [viewportToGraph] to convert.
///
/// Create it in a `State.initState` and dispose it in `State.dispose`.
class GraphViewerController extends ChangeNotifier {
  /// Creates a controller for [graph].
  GraphViewerController({
    required Graph graph,
    this._layoutConfig = const HierarchicalLayoutConfig(),
    double initialScale = 1,
    Offset initialOffset = Offset.zero,
    this.backgroundLayoutThreshold = 400,
  }) : _graph = graph,
       _layoutedGraph = graph,
       _positionBounds = GraphBounds.ofPositions(graph.nodes.values),
       _transform = ValueNotifier(GraphTransform(initialScale, initialOffset));

  /// Node count from which layouts run on a background isolate (except custom layouts and on the
  /// web, which run on the UI isolate).
  final int backgroundLayoutThreshold;

  /// Selection, hover and drag state.
  final GraphInteraction interaction = GraphInteraction();

  final ValueNotifier<GraphTransform> _transform;
  final ValueNotifier<TransformAnimationRequest?> _animation = ValueNotifier(null);
  final ValueNotifier<int> _structure = ValueNotifier(0);

  Graph _graph;
  Graph _layoutedGraph;
  LayoutConfig _layoutConfig;
  Rect _positionBounds;
  Size _canvasSize = Size.zero;
  Offset _contentOffset = Offset.zero;
  Map<String, Size> _measuredSizes = const {};
  Map<String, Offset> _manualPositions = const {};
  Graph? _manualLayout;
  bool _hasFittedInitially = false;
  GraphViewerConfig _config = const GraphViewerConfig();
  int _layoutGeneration = 0;
  int _animationVersion = 0;
  bool _layoutScheduled = false;
  bool _layoutRunning = false;
  bool _disposed = false;

  /// The graph as supplied, before layout.
  Graph get graph => _graph;

  /// The graph with layout positions (and measured sizes) applied: what the viewer shows.
  Graph get layoutedGraph => _layoutedGraph;

  /// The layout algorithm and its settings.
  LayoutConfig get layoutConfig => _layoutConfig;

  set layoutConfig(LayoutConfig value) {
    if (value == _layoutConfig) return;
    _layoutConfig = value;
    _scheduleLayout();
    _notifyStructure();
  }

  /// Current zoom level.
  double get scale => _transform.value.scale;

  /// Current pan offset in screen pixels.
  Offset get offset => _transform.value.offset;

  /// Current transform.
  GraphTransform get transform => _transform.value;

  /// Size of the viewer, [Size.zero] until it is laid out.
  Size get canvasSize => _canvasSize;

  /// Space reserved for overlay UI; [centerGraph] shifts the graph by half of it.
  Offset get contentOffset => _contentOffset;

  /// Positions placed by hand (dragging or [moveNode]), by node id.
  Map<String, Offset> get manualPositions => _manualPositions;

  /// Whether the graph has been laid out and fitted once. Useful to hide loading UI.
  bool get hasFittedInitially => _hasFittedInitially;

  /// Whether a layout pass is scheduled or running.
  bool get isLayoutPending => _layoutScheduled || _layoutRunning;

  /// Center of the node positions of [layoutedGraph]; the viewer puts it at the viewport center.
  Offset get graphCenter => _positionBounds.center;

  /// Swaps in a new graph and lays it out. Derive it from [graph] with `withNode`, `withEdge`,
  /// `rebuild`… An equal graph is a no-op.
  void updateGraph(Graph graph) {
    if (graph == _graph) return;
    _graph = graph;
    _scheduleLayout();
    _notifyStructure();
  }

  /// Lays the graph out again even though nothing changed.
  void relayout() => _scheduleLayout();

  /// Hands every node back to the layout algorithm and lays the graph out again.
  void clearManualPositions() {
    if (_manualPositions.isEmpty) return;
    _manualPositions = const {};
    _scheduleLayout();
    _notifyStructure();
  }

  /// Moves node [id] to [position] (graph space) and records it as a manual position, which
  /// [RelayoutPolicy.keepManual] reapplies after every layout pass. Unknown ids are ignored. The
  /// view is adjusted so that the other nodes stay where they are on screen.
  void moveNode(String id, Offset position) {
    final node = _layoutedGraph.nodes[id];
    if (node == null || node.position == position) return;
    final before = _positionBounds.center;
    final moved = _layoutedGraph.withNode(node.copyWith(position: position));
    _setLayoutedGraph(moved);
    _manualPositions = Map.unmodifiable({..._manualPositions, id: position});
    _manualLayout = moved;
    // The graph center moved; cancel that shift in the transform
    _setTransform(GraphTransform(scale, offset + (_positionBounds.center - before) * scale));
    _notifyStructure();
  }

  /// Moves node [id] by [delta] (graph space). See [moveNode].
  void moveNodeBy(String id, Offset delta) {
    final node = _layoutedGraph.nodes[id];
    if (node == null || delta == Offset.zero) return;
    moveNode(id, node.position + delta);
  }

  /// Reserves room for overlay UI, which [centerGraph] compensates for.
  void updateContentOffset(Offset value) {
    if (value == _contentOffset) return;
    _contentOffset = value;
    _notifyStructure();
  }

  /// Centers the graph in the viewport and scales it to fit (within the viewer's zoom limits).
  void centerGraph({bool animated = true}) {
    final centered = _contentOffset / 2;
    if (_layoutedGraph.nodes.isEmpty || _canvasSize.isEmpty) {
      updateTransform(scale: _clampScale(1), offset: centered, animated: animated);
      return;
    }
    final bounds = GraphBounds.ofNodes(_layoutedGraph.nodes.values);
    final padding = _config.contentPadding;
    final fitX = bounds.width > 0 ? _canvasSize.width * padding / bounds.width : 1.0;
    final fitY = bounds.height > 0 ? _canvasSize.height * padding / bounds.height : 1.0;
    updateTransform(scale: _clampScale(math.min(fitX, fitY)), offset: centered, animated: animated);
  }

  /// Zooms in one `zoomStep` about the viewport center, animated.
  void zoomIn() => _zoomAboutCenter(_config.zoomStep);

  /// Zooms out one `zoomStep` about the viewport center, animated.
  void zoomOut() => _zoomAboutCenter(1 / _config.zoomStep);

  /// Sets the transform, cancelling any running zoom or pan animation unless [animated].
  void updateTransform({double? scale, Offset? offset, bool animated = false}) {
    final target = GraphTransform(scale ?? this.scale, offset ?? this.offset);
    if (animated) {
      _animation.value = TransformAnimationRequest(target, ++_animationVersion);
      return;
    }
    _animation.value = null;
    _setTransform(target);
  }

  /// Converts a point in graph space to viewport coordinates.
  Offset graphToViewport(Offset graphPoint) =>
      _canvasSize.center(Offset.zero) + offset + (graphPoint - graphCenter) * scale;

  /// Converts a point in viewport coordinates to graph space.
  Offset viewportToGraph(Offset viewportPoint) =>
      (viewportPoint - _canvasSize.center(Offset.zero) - offset) / scale + graphCenter;

  // ---- Viewer plumbing --------------------------------------------------------------------------

  /// Fires on graph, layout, fit and configuration changes, not on transform changes.
  @internal
  Listenable get structureListenable => _structure;

  /// Fires on every transform change.
  @internal
  ValueListenable<GraphTransform> get transformListenable => _transform;

  /// The pending transform animation, `null` when none.
  @internal
  ValueListenable<TransformAnimationRequest?> get animationListenable => _animation;

  /// The configuration of the viewer showing this controller.
  @internal
  GraphViewerConfig get config => _config;

  /// Adopts the viewer's configuration.
  @internal
  void attachConfig(GraphViewerConfig config) {
    if (config == _config) return;
    final policyChanged = config.relayoutPolicy != _config.relayoutPolicy;
    _config = config;
    if (policyChanged) _scheduleLayout();
  }

  /// Adopts the viewer's size. Called during layout; lays the graph out again when it changed.
  @internal
  void reportCanvasSize(Size size) {
    if (size == _canvasSize) return;
    _canvasSize = size;
    _scheduleLayout();
  }

  /// Adopts measured sizes of nodes without a fixed size. Called during layout.
  @internal
  void reportMeasuredSizes(Map<String, Size> sizes) {
    if (mapEquals(sizes, _measuredSizes)) return;
    _measuredSizes = Map.unmodifiable(sizes);
    _scheduleLayout();
  }

  /// Whether [candidate] was produced by [moveNode] rather than by a layout pass.
  @internal
  bool isManualLayout(Graph candidate) => identical(candidate, _manualLayout);

  /// Writes an animation frame, unless [request] has been superseded.
  @internal
  void applyAnimationFrame(TransformAnimationRequest request, GraphTransform value) {
    if (!identical(_animation.value, request)) return;
    _setTransform(value);
  }

  /// Marks [request] finished.
  @internal
  void completeAnimation(TransformAnimationRequest request) {
    if (identical(_animation.value, request)) _animation.value = null;
  }

  /// Zooms by [factor] about [focalPoint] (viewport coordinates) and pans by [pan], clamped to the
  /// zoom limits. What pinch, pan and scroll gestures do.
  @internal
  void applyGesture({Offset focalPoint = Offset.zero, Offset pan = Offset.zero, double factor = 1}) {
    final newScale = _clampScale(scale * factor);
    final actual = newScale / scale;
    final pivot = focalPoint - _canvasSize.center(Offset.zero);
    updateTransform(scale: newScale, offset: pivot * (1 - actual) + offset * actual + pan);
  }

  void _zoomAboutCenter(double factor) {
    final newScale = _clampScale(scale * factor);
    updateTransform(scale: newScale, offset: offset * (newScale / scale), animated: true);
  }

  double _clampScale(double value) => value.clamp(_config.minScale, _config.maxScale);

  void _setTransform(GraphTransform value) {
    if (value == _transform.value) return;
    _transform.value = value;
    notifyListeners();
  }

  void _notifyStructure() {
    _structure.value++;
    notifyListeners();
  }

  void _setLayoutedGraph(Graph graph) {
    _layoutedGraph = graph;
    _positionBounds = GraphBounds.ofPositions(graph.nodes.values);
  }

  void _scheduleLayout() {
    _layoutGeneration++;
    if (_layoutScheduled) return;
    _layoutScheduled = true;
    scheduleMicrotask(_runLayout);
  }

  Future<void> _runLayout() async {
    _layoutScheduled = false;
    if (_disposed) return;
    final generation = _layoutGeneration;
    final sized = _graph.withMeasuredSizes(_measuredSizes);
    final canvas = _canvasSize;
    Graph laid = sized;
    if (!canvas.isEmpty) {
      final config = _layoutConfig.withCanvas(canvas);
      final background = !kIsWeb && config is! CustomLayoutConfig && sized.nodes.length >= backgroundLayoutThreshold;
      if (background) {
        _layoutRunning = true;
        try {
          laid = await compute(_BackgroundLayout.run, (sized, config));
        } on Object catch (error, stack) {
          // Never leave the graph unlaid: report and lay out on this isolate instead
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'interactive_graphs',
              context: ErrorDescription('while laying out the graph on a background isolate'),
            ),
          );
          laid = GraphLayout.run(sized, config);
        } finally {
          _layoutRunning = false;
        }
      } else {
        laid = GraphLayout.run(sized, config);
      }
    }
    // A newer request superseded this one
    if (_disposed || generation != _layoutGeneration) return;

    _applyLayout(laid);
    _applyInitialFit();
    _notifyStructure();
  }

  void _applyLayout(Graph laid) {
    final nodeIds = laid.nodes.keys.toSet();
    if (_manualPositions.keys.any((id) => !nodeIds.contains(id))) {
      _manualPositions = Map.unmodifiable({
        for (final entry in _manualPositions.entries)
          if (nodeIds.contains(entry.key)) entry.key: entry.value,
      });
    }
    var result = laid;
    if (_config.relayoutPolicy == RelayoutPolicy.keepManual && _manualPositions.isNotEmpty) {
      result = laid.withNodes([
        for (final MapEntry(key: id, value: position) in _manualPositions.entries)
          if (laid.nodes[id] case final node? when node.position != position) node.copyWith(position: position),
      ]);
    }
    _setLayoutedGraph(result);
    interaction.retain(nodeIds, {for (final edge in result.edges) edge.id});
  }

  void _applyInitialFit() {
    if (_hasFittedInitially || _canvasSize.isEmpty) return;
    final nodes = _layoutedGraph.nodes.values;
    // Wait for the renderer to measure the nodes, the fit depends on their sizes
    if (nodes.isEmpty || nodes.every((node) => node.size == null)) return;
    if (_config.fitToContent) centerGraph(animated: false);
    _hasFittedInitially = true;
  }

  @override
  void dispose() {
    _disposed = true;
    interaction.dispose();
    _transform.dispose();
    _animation.dispose();
    _structure.dispose();
    super.dispose();
  }
}

/// Entry point of background layouts; static so it can cross into an isolate.
abstract final class _BackgroundLayout {
  static Graph run((Graph, LayoutConfig) args) => GraphLayout.run(args.$1, args.$2);
}
