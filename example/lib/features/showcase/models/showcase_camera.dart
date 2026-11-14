import 'dart:async';
import 'dart:math' as math;

import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/showcase/models/camera_request.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_metrics.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_pacer.dart';
import 'package:material_ui/material_ui.dart';

/// Moves the camera of the showcase for the camera requests of its notifier: fits the graph, zooms
/// in on a step or pans from one step to another, in the room the overlays leave (the content
/// insets of [controller]).
class ShowcaseCamera {
  /// Creates the camera of [controller]; [vsync] drives its pans.
  ShowcaseCamera({required this.controller, required TickerProvider vsync}) : _pan = AnimationController(vsync: vsync) {
    _pan.addListener(_onPanTick);
  }

  /// The viewer state to move.
  final GraphViewerController controller;

  /// Whether a pan jumps to its end instead of travelling there.
  bool reduceMotion = false;

  final AnimationController _pan;
  late final CurvedAnimation _panCurve = CurvedAnimation(parent: _pan, curve: Curves.easeInOutSine);
  TourPacer? _pacer;
  ({Offset from, Offset to, double scale})? _panPath;
  int _userMoves = 0;
  bool _disposed = false;

  /// Moves the camera for [request], once the layout stops changing unless it says otherwise. A
  /// newer request replaces it, and a camera move by the user in the meantime drops it.
  Future<void> follow(CameraRequest request) async {
    if (request.version == 0) return;
    _pacer?.cancel();
    _stopPan();
    final pacer = _pacer = TourPacer();
    final userMoves = _userMoves;
    try {
      if (request.awaitLayout) {
        await pacer.settle(
          controller,
          () => controller.layoutedGraph,
          quiet: const Duration(milliseconds: 80),
          timeout: const Duration(milliseconds: 1200),
        );
      }
      // The user took over the camera in the meantime
      if (_disposed || _userMoves != userMoves) return;
      switch (request) {
        case CameraRequest(focusId: null):
          controller.centerGraph();
        case CameraRequest(focusId: final String from, panTo: final String to):
          await _panBetween(pacer, from, to, request.panMillis);
        case CameraRequest(focusId: final String id):
          _focusOn(id);
      }
    } on TourCancelled {
      // A newer request took over
    }
  }

  /// A pan, drag or scroll by the user: stops a running pan and drops a request still waiting.
  void userMoved() {
    _userMoves++;
    _stopPan();
  }

  /// Stops every camera move and releases the pan animation.
  void dispose() {
    _disposed = true;
    _pacer?.cancel();
    _pan.removeListener(_onPanTick);
    _panCurve.dispose();
    _pan.dispose();
  }

  /// Zoom that fits an expanded step comfortably.
  double get _focusScale =>
      math.max(math.min(1.1, controller.canvasSize.width * 0.45 / ShowcaseMetrics.expandedStepWidth), 0.4);

  /// Zooms in on step [id].
  void _focusOn(String id) {
    final node = controller.layoutedGraph.nodes[id];
    if (node == null) return;
    controller.centerOn(node.position, scale: _focusScale);
  }

  /// Zooms in on [fromId], then pans to [toId] over [millis] at the same zoom.
  Future<void> _panBetween(TourPacer pacer, String fromId, String toId, int millis) async {
    final nodes = controller.layoutedGraph.nodes;
    final from = nodes[fromId]?.position;
    final to = nodes[toId]?.position;
    if (from == null || to == null) return;
    final scale = _focusScale;
    controller.centerOn(from, scale: scale);
    await pacer.wait(ShowcaseMetrics.panLeadIn);
    if (reduceMotion) {
      controller.centerOn(to, scale: scale, animated: false);
      return;
    }
    _panPath = (from: from, to: to, scale: scale);
    _pan
      ..duration = Duration(milliseconds: millis)
      ..forward(from: 0);
  }

  void _onPanTick() {
    final path = _panPath;
    if (path == null) return;
    final point = Offset.lerp(path.from, path.to, _panCurve.value) ?? path.to;
    controller.centerOn(point, scale: path.scale, animated: false);
  }

  void _stopPan() {
    _pan.stop();
    _panPath = null;
  }
}
