import 'dart:async';
import 'dart:ui';

import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_layout.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_metrics.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_state.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_steps.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_pacer.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_step.dart';
import 'package:interactive_graphs_example/features/showcase/providers/showcase_provider.dart';

/// Plays the timed sequences of the showcase: a run of the order, the guided tour and a step
/// shrinking away before it leaves the graph. It tells the notifier what to show and moves nodes
/// and the selection on [controller]; the camera follows the notifier's camera requests.
class ShowcaseDirector {
  /// Creates the director of [controller]; [notifier] and [state] read the showcase provider.
  ShowcaseDirector({
    required this.controller,
    required ShowcaseNotifier Function() notifier,
    required ShowcaseState Function() state,
  }) : _readNotifier = notifier,
       _readState = state;

  /// The viewer state whose nodes and selection the tour moves.
  final GraphViewerController controller;

  /// Whether scripted node drags jump to their end instead of travelling there.
  bool reduceMotion = false;

  final ShowcaseNotifier Function() _readNotifier;
  final ShowcaseState Function() _readState;
  final Set<Timer> _leaveTimers = {};
  TourPacer? _tourPacer;
  TourPacer? _runPacer;
  bool _disposed = false;

  /// Starts or stops playing the order through.
  void toggleRun() {
    if (_runPacer != null) {
      _cancelRun();
      return;
    }
    unawaited(_runOnce());
  }

  /// Starts or stops the guided tour.
  void toggleTour() {
    if (_tourPacer != null) {
      stopTour();
      return;
    }
    unawaited(_runTour());
  }

  /// Cancels the tour and the order run.
  void stopTour() {
    final pacer = _tourPacer;
    if (pacer != null) {
      _tourPacer = null;
      pacer.cancel();
      _notifier.endTour();
    }
    _cancelRun();
  }

  /// Back to the plain order in the home layout.
  void reset() {
    stopTour();
    controller.clearManualPositions();
    _restore(ShowcaseSteps.orderIds);
    _notifier.fit();
  }

  /// Shrinks step [id] away, then drops it from the graph.
  void remove(String id) {
    if (!_notifier.startLeaving(id)) return;
    late final Timer timer;
    timer = Timer(ShowcaseMetrics.leaveDelay, () {
      _leaveTimers.remove(timer);
      if (!_disposed) _notifier.dropStep(id);
    });
    _leaveTimers.add(timer);
  }

  /// Stops every sequence without touching the provider.
  void dispose() {
    _disposed = true;
    _tourPacer?.cancel();
    _runPacer?.cancel();
    for (final timer in _leaveTimers) {
      timer.cancel();
    }
    _leaveTimers.clear();
  }

  ShowcaseNotifier get _notifier => _readNotifier();

  /// Resets run, expansion and styles, showing [ids].
  void _restore(List<String> ids) {
    _cancelRun();
    _notifier.restore(ids);
  }

  // ---- Order run --------------------------------------------------------------------------------

  Future<void> _runOnce() async {
    final pacer = _runPacer = TourPacer();
    _notifier.setRunning(true);
    try {
      await _runOrder(pacer);
    } on TourCancelled {
      // Stopped by the user, a reset or the tour
    } finally {
      if (!_disposed && identical(_runPacer, pacer)) {
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
      for (final id in _readState().visibleIds)
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

  Future<void> _runTour() async {
    final pacer = _tourPacer = TourPacer();
    _notifier.startTour();
    try {
      await _playTour(pacer);
    } on TourCancelled {
      // Stopped by the user or a reset
    } finally {
      if (!_disposed && identical(_tourPacer, pacer)) {
        _tourPacer = null;
        _notifier.endTour();
      }
    }
  }

  /// Scripted walk through the features, timed for a screen recording.
  Future<void> _playTour(TourPacer pacer) async {
    final notifier = _notifier;
    final interaction = controller.interaction;
    Future<void> wait(int millis) => pacer.wait(Duration(milliseconds: millis));

    // Start from the first three nodes
    interaction.clearSelection();
    controller.clearManualPositions();
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
    final home = _readState().homeLayout;
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
    controller.clearManualPositions();
    await wait(1400);

    // Add and remove nodes
    notifier.show(TourStep.runtime);
    for (var i = 0; i < 3; i++) {
      notifier.addStep();
      await wait(1000);
    }
    final extras = ShowcaseSteps.extraSteps.keys.toList();
    remove(extras[1]);
    await wait(1000);
    remove(extras[2]);
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
    if (reduceMotion) {
      controller.moveNodeBy(id, const Offset(0, 135));
      return;
    }
    for (var i = 0; i < 45; i++) {
      controller.moveNodeBy(id, const Offset(0, 3));
      await pacer.wait(const Duration(milliseconds: 16));
    }
  }
}
