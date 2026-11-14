import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/views/playground_view.dart';
import 'package:interactive_graphs_example/features/showcase/models/camera_request.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_camera.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_director.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_layout.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_metrics.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_state.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_graph.dart';
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
  late final ShowcaseDirector _director;
  late final ShowcaseCamera _camera;
  late final AnimationController _flow = AnimationController(vsync: this, duration: ShowcaseMetrics.flowPeriod);
  final GraphViewerConfig _config = GraphViewerConfig(
    contentPadding: 0.88,
    minScale: 0.2,
    maxScale: 1.6,
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
  ShowcaseLayout? _requestedHome;
  double _travelled = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(showcaseProvider);
    _controller = GraphViewerController(
      graph: StepGraph.build(state.visibleIds, state.layout),
      layoutConfig: state.layout.config,
    )..updateContentInsets(_insets(state));
    _director = ShowcaseDirector(controller: _controller, notifier: () => _notifier, state: () => _state);
    _camera = ShowcaseCamera(controller: _controller, vsync: this);
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
    _director.reduceMotion = _reduceMotion;
    _camera.reduceMotion = _reduceMotion;
    _syncFlow();
  }

  @override
  void dispose() {
    _director.dispose();
    _camera.dispose();
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
            onToggleTour: _director.toggleTour,
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
                        onToggleRun: _director.toggleRun,
                        onAddStep: _notifier.addStep,
                        onZoomOut: _controller.zoomOut,
                        onZoomIn: _controller.zoomIn,
                        onFit: _controller.centerGraph,
                        onReset: _director.reset,
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

  void _onCameraChanged(CameraRequest? previous, CameraRequest next) => unawaited(_camera.follow(next));

  void _onCaptionChanged(bool? previous, bool next) => _controller.updateContentInsets(_insets(_state));

  void _onRunningChanged(bool? previous, bool next) => _syncFlow();

  /// Runs the parcel animation while some step is running.
  void _syncFlow() {
    if (_state.hasRunningSteps && !_reduceMotion) {
      if (!_flow.isAnimating) _flow.repeat();
      return;
    }
    _flow.stop();
  }

  /// Room the tour caption and the toolbar take from the graph.
  EdgeInsets _insets(ShowcaseState state) {
    if (state.caption == null) return const EdgeInsets.only(bottom: ShowcaseMetrics.bottomInset);
    return const EdgeInsets.only(top: ShowcaseMetrics.captionHeight, bottom: ShowcaseMetrics.bottomInset);
  }

  // ---- Controls ---------------------------------------------------------------------------------

  void _onNodeTap(GraphNode node) => _notifier.toggleExpanded(node.id);

  void _onNodeLongPress(GraphNode node) => _director.remove(node.id);

  void _onCanvasTap() => _notifier.collapseAll();

  void _toggleTheme() => ref.read(themeModeProvider.notifier).toggle(MediaQuery.platformBrightnessOf(context));

  void _openPlayground() {
    _director.stopTour();
    Navigator.of(context).push(PlaygroundView.route());
  }

  void _openStressTest() {
    _director.stopTour();
    Navigator.of(context).push(StressTestView.route());
  }

  // ---- User camera moves ------------------------------------------------------------------------

  void _onPointerDown(PointerDownEvent event) => _travelled = 0;

  void _onPointerMove(PointerMoveEvent event) {
    _travelled += event.delta.distance;
    if (_travelled > kTouchSlop) _camera.userMoved();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) _camera.userMoved();
  }
}
