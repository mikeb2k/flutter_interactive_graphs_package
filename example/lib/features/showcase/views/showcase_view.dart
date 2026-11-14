import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/views/playground_view.dart';
import 'package:interactive_graphs_example/features/showcase/models/camera_request.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_camera.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_layout.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_metrics.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_state.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_steps.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_graph.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_pacer.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_step.dart';
import 'package:interactive_graphs_example/features/showcase/providers/showcase_provider.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/showcase_canvas.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/showcase_header.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/showcase_toolbar.dart';
import 'package:interactive_graphs_example/features/showcase/widgets/tour_caption.dart';
import 'package:interactive_graphs_example/features/stress_test/views/stress_test_view.dart';
import 'package:interactive_graphs_example/providers/theme_mode_provider.dart';
import 'package:material_ui/material_ui.dart';

/// Showcase of most interactive_graphs features on an online order travelling from checkout to
/// the front door, with a guided tour for screen recordings. The start screen of the example.
///
/// Tap a step to expand it, long-press to remove it, drag to move it; the toolbar adds steps,
/// zooms, fits, resets and plays the order through.
class ShowcaseView extends ConsumerStatefulWidget {
  /// Creates the screen.
  const ShowcaseView({super.key});

  /// Route to this screen.
  static Route<void> route() => MaterialPageRoute<void>(builder: (_) => const ShowcaseView());

  @override
  ConsumerState<ShowcaseView> createState() => _ShowcaseViewState();
}

class _ShowcaseViewState extends ConsumerState<ShowcaseView> with TickerProviderStateMixin {
  late final GraphViewerController _controller;
  late final AnimationController _flow = AnimationController(vsync: this, duration: ShowcaseMetrics.flowPeriod);
  late final AnimationController _pan = AnimationController(vsync: this);
  late final CurvedAnimation _panCurve = CurvedAnimation(parent: _pan, curve: Curves.easeInOutSine);
  final GraphViewerConfig _config = GraphViewerConfig(
    contentPadding: 0.86,
    minScale: 0.2,
    maxScale: 2,
    selectionMode: SelectionMode.single,
    nodeDragEnabled: true,
    hoverEnabled: true,
    edgeSelectionMode: SelectionMode.single,
    edgeHoverEnabled: true,
    transformSpring: SpringDescription.withDampingRatio(mass: 1, stiffness: 70),
    layoutSpring: SpringDescription.withDampingRatio(mass: 1, stiffness: 200, ratio: 0.8),
    enterDuration: const Duration(milliseconds: 300),
  );
  late final GraphInteractionCallbacks _callbacks = GraphInteractionCallbacks(
    onNodeTap: _onNodeTap,
    onNodeLongPress: _onNodeLongPress,
    onCanvasTap: _onCanvasTap,
  );
  final Set<Timer> _leaveTimers = {};
  TourPacer? _tourPacer;
  TourPacer? _runPacer;
  TourPacer? _cameraPacer;
  ({Offset from, Offset to, double scale, double top, double bottom})? _panPath;
  ShowcaseLayout? _requestedHome;
  int _userCameraMoves = 0;
  double _travelled = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(showcaseProvider);
    _controller = GraphViewerController(
      graph: StepGraph.build(state.visibleIds, state.layout),
      layoutConfig: state.layout.config,
    )..updateContentInsets(EdgeInsets.only(top: _topInset(state), bottom: ShowcaseMetrics.bottomInset));
    _pan.addListener(_onPanTick);
    ref
      ..listenManual(showcaseProvider.select((state) => (state.visibleIds, state.layout)), _onGraphChanged)
      ..listenManual(showcaseProvider.select((state) => state.camera), _onCameraChanged)
      ..listenManual(showcaseProvider.select((state) => state.caption != null), _onCaptionChanged)
      ..listenManual(showcaseProvider.select((state) => state.hasRunningSteps), _onRunningChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _syncFlow();
  }

  @override
  void dispose() {
    _tourPacer?.cancel();
    _runPacer?.cancel();
    _cameraPacer?.cancel();
    for (final timer in _leaveTimers) {
      timer.cancel();
    }
    _leaveTimers.clear();
    _pan.removeListener(_onPanTick);
    _panCurve.dispose();
    _pan.dispose();
    _flow.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(showcaseProvider);
    _adoptHomeLayout(ShowcaseLayout.homeFor(MediaQuery.sizeOf(context)));
    final graph = _controller.graph;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: Column(
        children: [
          ShowcaseHeader(
            steps: graph.nodes.length,
            connections: graph.edges.length,
            layout: state.layout,
            edgeStyle: state.edgeStyle,
            isTouring: state.isTouring,
            isDark: Theme.of(context).brightness == Brightness.dark,
            onToggleTour: _toggleTour,
            onToggleTheme: _toggleTheme,
            onOpenPlayground: _openPlayground,
            onOpenStressTest: _openStressTest,
            onSelectLayout: _notifier.selectLayout,
            onSelectEdgeStyle: _notifier.selectEdgeStyle,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Listener(
                      onPointerDown: _onPointerDown,
                      onPointerMove: _onPointerMove,
                      onPointerSignal: _onPointerSignal,
                      child: ShowcaseCanvas(
                        controller: _controller,
                        state: state,
                        flowPhase: _flow,
                        config: _config,
                        callbacks: _callbacks,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: TourCaption(caption: state.caption),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(ShowcaseMetrics.toolbarMargin),
                      child: ShowcaseToolbar(
                        isRunning: state.isRunning,
                        onToggleRun: _toggleRun,
                        onAddStep: _notifier.addStep,
                        onZoomOut: _controller.zoomOut,
                        onZoomIn: _controller.zoomIn,
                        onFit: _fit,
                        onReset: _reset,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ShowcaseNotifier get _notifier => ref.read(showcaseProvider.notifier);

  ShowcaseState get _state => ref.read(showcaseProvider);

  // ---- Provider wiring --------------------------------------------------------------------------

  /// Follows the window's home layout; the first one also becomes the layout shown.
  void _adoptHomeLayout(ShowcaseLayout home) {
    if (home == _requestedHome) return;
    final first = _requestedHome == null;
    _requestedHome = home;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifier.setHomeLayout(home, apply: first);
    });
  }

  void _onGraphChanged((List<String>, ShowcaseLayout)? previous, (List<String>, ShowcaseLayout) next) {
    final (visibleIds, layout) = next;
    _controller
      ..layoutConfig = layout.config
      ..updateGraph(StepGraph.build(visibleIds, layout));
  }

  void _onCameraChanged(CameraRequest? previous, CameraRequest next) => unawaited(_followCamera(next));

  void _onCaptionChanged(bool? previous, bool next) =>
      _controller.updateContentInsets(EdgeInsets.only(top: _topInset(_state), bottom: ShowcaseMetrics.bottomInset));

  void _onRunningChanged(bool? previous, bool next) => _syncFlow();

  /// Runs the parcel animation while some step is running.
  void _syncFlow() {
    if (_state.hasRunningSteps && !_reduceMotion) {
      if (!_flow.isAnimating) _flow.repeat();
      return;
    }
    _flow.stop();
  }

  double _topInset(ShowcaseState state) {
    if (state.caption == null) return 0;
    return ShowcaseMetrics.captionHeight;
  }

  // ---- Controls ---------------------------------------------------------------------------------

  void _onNodeTap(GraphNode node) => _notifier.toggleExpanded(node.id);

  void _onNodeLongPress(GraphNode node) => _remove(node.id);

  void _onCanvasTap() => _notifier.collapseAll();

  void _toggleTheme() => ref.read(themeModeProvider.notifier).toggle(MediaQuery.platformBrightnessOf(context));

  void _openPlayground() {
    _stopTour();
    Navigator.of(context).push(PlaygroundView.route());
  }

  void _openStressTest() {
    _stopTour();
    Navigator.of(context).push(StressTestView.route());
  }

  void _fit() => _controller.fitBetween(_topInset(_state), ShowcaseMetrics.bottomInset);

  /// Back to the plain order in the home layout.
  void _reset() {
    _stopTour();
    _controller.clearManualPositions();
    _restore(ShowcaseSteps.orderIds);
    _notifier.fit();
  }

  /// Resets run, expansion and styles, showing [ids].
  void _restore(List<String> ids) {
    _cancelRun();
    _notifier.restore(ids);
  }

  /// Shrinks step [id] away, then drops it from the graph.
  void _remove(String id) {
    if (!_notifier.startLeaving(id)) return;
    late final Timer timer;
    timer = Timer(ShowcaseMetrics.leaveDelay, () {
      _leaveTimers.remove(timer);
      if (mounted) _notifier.dropStep(id);
    });
    _leaveTimers.add(timer);
  }

  // ---- Order run --------------------------------------------------------------------------------

  /// Starts or stops playing the order through.
  void _toggleRun() {
    if (_runPacer != null) {
      _cancelRun();
      return;
    }
    unawaited(_runOnce());
  }

  Future<void> _runOnce() async {
    final pacer = _runPacer = TourPacer();
    _notifier.setRunning(true);
    try {
      await _runOrder(pacer);
    } on TourCancelled {
      // Stopped by the user, a reset or the tour
    } finally {
      if (mounted && identical(_runPacer, pacer)) {
        _runPacer = null;
        _notifier.setRunning(false);
      }
    }
  }

  void _cancelRun() {
    final pacer = _runPacer;
    if (pacer == null) return;
    _runPacer = null;
    pacer.cancel();
    _notifier.setRunning(false);
  }

  /// Plays the order through, with a declined card and a missed delivery.
  Future<void> _runOrder(TourPacer pacer) async {
    _notifier.clearStatuses();
    await _step(pacer, 'order', 700);
    await Future.wait([_step(pacer, 'stock', 1300), _payment(pacer)]);
    await _step(pacer, 'pack', 1200);
    // The visible extra steps after packing run side by side
    await Future.wait([
      for (final id in _state.visibleIds)
        if (ShowcaseSteps.extraSteps[id]?.after == 'pack') _step(pacer, id, 900),
    ]);
    await _step(pacer, 'hub', 1000);
    await Future.wait([_step(pacer, 'notify', 900), _delivery(pacer)]);
  }

  Future<void> _payment(TourPacer pacer) async {
    await _step(pacer, 'payment', 900, fails: true);
    await _step(pacer, 'payment', 1000, retry: true);
    await _step(pacer, 'receipt', 800);
  }

  Future<void> _delivery(TourPacer pacer) async {
    await _step(pacer, 'courier', 1100, fails: true);
    await _step(pacer, 'hub', 700);
    await _step(pacer, 'courier', 1000);
    await _step(pacer, 'delivered', 900);
  }

  /// Runs step [id] for [millis], then marks it done or failed. Skips steps not in the graph.
  Future<void> _step(TourPacer pacer, String id, int millis, {bool fails = false, bool retry = false}) async {
    if (!_notifier.beginStep(id, retry: retry)) return;
    await pacer.wait(Duration(milliseconds: millis));
    _notifier.endStep(id, failed: fails);
  }

  // ---- Guided tour ------------------------------------------------------------------------------

  /// Starts or stops the guided tour.
  void _toggleTour() {
    if (_tourPacer != null) {
      _stopTour();
      return;
    }
    unawaited(_runTour());
  }

  Future<void> _runTour() async {
    final pacer = _tourPacer = TourPacer();
    _notifier.startTour();
    try {
      await _playTour(pacer);
    } on TourCancelled {
      // Stopped by the user or a reset
    } finally {
      if (mounted && identical(_tourPacer, pacer)) {
        _tourPacer = null;
        _notifier.endTour();
      }
    }
  }

  /// Cancels the tour and the order run.
  void _stopTour() {
    final pacer = _tourPacer;
    if (pacer != null) {
      _tourPacer = null;
      pacer.cancel();
      _notifier.endTour();
    }
    _cancelRun();
  }

  /// Scripted walk through the features, timed for a screen recording.
  Future<void> _playTour(TourPacer pacer) async {
    final notifier = _notifier;
    final interaction = _controller.interaction;
    Future<void> wait(int millis) => pacer.wait(Duration(milliseconds: millis));

    // Start from the first three nodes
    interaction.clearSelection();
    _controller.clearManualPositions();
    _restore(ShowcaseSteps.orderIds.take(3).toList());
    notifier
      ..fit()
      ..show(TourStep.intro);
    await wait(2000);

    // Grow the graph one node at a time
    notifier.show(TourStep.grow);
    for (final id in ShowcaseSteps.orderIds.skip(3)) {
      notifier.reveal(id);
      await wait(450);
    }
    await wait(1200);

    // Play the order through while the camera pans along
    notifier
      ..show(TourStep.widgets)
      ..pan('order', 'delivered', 9000);
    await pacer.wait(ShowcaseMetrics.panLeadIn);
    await _runOrder(pacer);
    notifier.fit(awaitLayout: false);
    await wait(1600);

    // Expand nodes
    notifier
      ..show(TourStep.measured)
      ..toggleExpanded('payment');
    await wait(2600);
    notifier.toggleExpanded('payment');
    await wait(700);
    notifier.toggleExpanded('courier');
    await wait(2400);
    notifier.toggleExpanded('courier');
    await wait(1000);

    // Switch layouts
    final home = _state.homeLayout;
    notifier
      ..show(TourStep.layoutHierarchical)
      ..selectLayout(home.otherHierarchical);
    await wait(1500);
    notifier
      ..show(TourStep.layoutForceDirected)
      ..selectLayout(ShowcaseLayout.organic);
    await wait(1500);
    notifier
      ..show(TourStep.layoutCustom)
      ..selectLayout(ShowcaseLayout.orbit);
    await wait(1700);

    // Edge styles, back on the home layout
    notifier
      ..show(TourStep.edges)
      ..selectLayout(home);
    await wait(1800);
    notifier.selectEdgeStyle(ShowcaseEdgeStyle.circuit);
    await wait(1400);
    notifier.selectEdgeStyle(ShowcaseEdgeStyle.straight);
    await wait(1200);
    notifier.selectEdgeStyle(ShowcaseEdgeStyle.curves);
    await wait(1000);

    // Interaction
    notifier.show(TourStep.interaction);
    interaction.select('pack');
    await wait(1800);
    interaction.selectEdge('courier->hub');
    await wait(1800);
    interaction.clearSelection();
    await _dragDown(pacer, 'delivered');
    await wait(900);
    _controller.clearManualPositions();
    await wait(1400);

    // Add and remove nodes
    notifier.show(TourStep.runtime);
    for (var i = 0; i < 3; i++) {
      notifier.addStep();
      await wait(1000);
    }
    final extras = ShowcaseSteps.extraSteps.keys.toList();
    _remove(extras[1]);
    await wait(1000);
    _remove(extras[2]);
    await wait(1400);

    // Camera
    notifier
      ..show(TourStep.camera)
      ..focus('hub');
    await wait(2000);
    notifier.focus('order');
    await wait(2000);
    notifier.fit();
    await wait(1600);

    // Outro
    notifier.show(TourStep.outro);
    await _runOrder(pacer);
    await wait(2500);
  }

  /// Drags node [id] down by 135 pixels as a hand would, or in one jump with reduced motion.
  Future<void> _dragDown(TourPacer pacer, String id) async {
    if (_reduceMotion) {
      _controller.moveNodeBy(id, const Offset(0, 135));
      return;
    }
    for (var i = 0; i < 45; i++) {
      _controller.moveNodeBy(id, const Offset(0, 3));
      await pacer.wait(const Duration(milliseconds: 16));
    }
  }

  // ---- Camera -----------------------------------------------------------------------------------

  /// Moves the camera for [request], once the layout stops changing unless it says otherwise. A
  /// newer request replaces it, and a camera move by the user in the meantime drops it.
  Future<void> _followCamera(CameraRequest request) async {
    if (request.version == 0) return;
    _cameraPacer?.cancel();
    _stopPan();
    final pacer = _cameraPacer = TourPacer();
    final userMoves = _userCameraMoves;
    try {
      if (request.awaitLayout) {
        await pacer.settle(
          _controller,
          () => _controller.layoutedGraph,
          quiet: const Duration(milliseconds: 80),
          timeout: const Duration(milliseconds: 1200),
        );
      }
      // The user took over the camera in the meantime
      if (!mounted || _userCameraMoves != userMoves) return;
      final top = _topInset(_state);
      const bottom = ShowcaseMetrics.bottomInset;
      switch (request) {
        case CameraRequest(focusId: null):
          _controller.fitBetween(top, bottom);
        case CameraRequest(focusId: final String from, panTo: final String to):
          await _panBetween(pacer, from, to, request.panMillis, top, bottom);
        case CameraRequest(focusId: final String id):
          _controller.focusOn(id, top, bottom);
      }
    } on TourCancelled {
      // A newer request took over
    }
  }

  /// Zooms in on [fromId], then pans to [toId] over [millis] at the same zoom.
  Future<void> _panBetween(TourPacer pacer, String fromId, String toId, int millis, double top, double bottom) async {
    final nodes = _controller.layoutedGraph.nodes;
    final from = nodes[fromId]?.position;
    final to = nodes[toId]?.position;
    if (from == null || to == null) return;
    final scale = _controller.focusScale;
    _controller.moveCamera(from, scale, top, bottom);
    await pacer.wait(ShowcaseMetrics.panLeadIn);
    if (_reduceMotion) {
      _controller.moveCamera(to, scale, top, bottom, animated: false);
      return;
    }
    _panPath = (from: from, to: to, scale: scale, top: top, bottom: bottom);
    _pan
      ..duration = Duration(milliseconds: millis)
      ..forward(from: 0);
  }

  void _onPanTick() {
    final path = _panPath;
    if (path == null) return;
    final point = Offset.lerp(path.from, path.to, _panCurve.value) ?? path.to;
    _controller.moveCamera(point, path.scale, path.top, path.bottom, animated: false);
  }

  void _stopPan() {
    _pan.stop();
    _panPath = null;
  }

  // ---- User camera moves ------------------------------------------------------------------------

  void _onPointerDown(PointerDownEvent event) => _travelled = 0;

  void _onPointerMove(PointerMoveEvent event) {
    _travelled += event.delta.distance;
    if (_travelled > kTouchSlop) _onUserCameraMove();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) _onUserCameraMove();
  }

  /// Pans, drags and scrolls by the user; a camera move requested before one is dropped.
  void _onUserCameraMove() {
    _userCameraMoves++;
    _stopPan();
  }
}
