import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_graphs_example/features/showcase/models/camera_request.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_layout.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_state.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_steps.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_status.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_step.dart';

/// State of the showcase screen.
final showcaseProvider = NotifierProvider.autoDispose<ShowcaseNotifier, ShowcaseState>(ShowcaseNotifier.new);

/// Changes the showcase: steps, layout, edge style, run status, tour chapter and camera requests.
/// `ShowcaseDirector` plays the timed sequences (tour, order run, step removal) and `ShowcaseCamera`
/// moves the camera.
class ShowcaseNotifier extends Notifier<ShowcaseState> {
  @override
  ShowcaseState build() => ShowcaseState.initial();

  /// Adopts the layout that suits the window; with [apply] also switches to it (on first show).
  void setHomeLayout(ShowcaseLayout home, {bool apply = false}) {
    state = state.copyWith(homeLayout: home, layout: apply ? home : null);
  }

  /// Switches the layout and refits once it lands.
  void selectLayout(ShowcaseLayout layout) {
    if (layout == state.layout) return;
    state = state.copyWith(layout: layout);
    fit();
  }

  /// Switches the edge shape.
  void selectEdgeStyle(ShowcaseEdgeStyle style) => state = state.copyWith(edgeStyle: style);

  /// Expands and focuses step [id], or collapses it and refits.
  void toggleExpanded(String id) {
    if (state.expanded.contains(id)) {
      state = state.copyWith(expanded: {...state.expanded}..remove(id));
      fit();
    } else {
      state = state.copyWith(expanded: {...state.expanded, id});
      focus(id);
    }
  }

  /// Collapses every expanded step.
  void collapseAll() {
    if (state.expanded.isEmpty) return;
    state = state.copyWith(expanded: const {});
    fit();
  }

  /// Shows one more order step and refits.
  void reveal(String id) {
    if (state.visibleIds.contains(id)) return;
    state = state.copyWith(visibleIds: [...state.visibleIds, id]);
    fit();
  }

  /// Adds the next extra step and refits; nothing when all are shown.
  void addStep() {
    final next = ShowcaseSteps.nextExtra(state.visibleIds);
    if (next == null) return;
    state = state.copyWith(visibleIds: [...state.visibleIds, next]);
    fit();
  }

  /// Starts shrinking step [id] away. Returns whether it started: the order itself stays, as
  /// everything hangs off it. Finish with [dropStep].
  bool startLeaving(String id) {
    if (id == ShowcaseSteps.rootId || !state.visibleIds.contains(id) || state.leaving.contains(id)) return false;
    state = state.copyWith(leaving: {...state.leaving, id});
    return true;
  }

  /// Removes step [id] from the graph and refits.
  void dropStep(String id) {
    state = state.copyWith(
      visibleIds: [...state.visibleIds]..remove(id),
      leaving: {...state.leaving}..remove(id),
      expanded: {...state.expanded}..remove(id),
    );
    fit();
  }

  /// Resets run, expansion and styles to the home layout, showing [ids].
  void restore(List<String> ids) {
    state = state.copyWith(
      statuses: const {},
      expanded: const {},
      leaving: const {},
      layout: state.homeLayout,
      edgeStyle: ShowcaseEdgeStyle.curves,
      entranceDelays: ShowcaseSteps.staggered(ids),
      visibleIds: [...ids],
    );
  }

  /// Marks the order run started or stopped.
  void setRunning(bool running) => state = state.copyWith(isRunning: running);

  /// Clears the status of every step.
  void clearStatuses() => state = state.copyWith(statuses: const {});

  /// Starts step [id] (as a retry when [retry]); returns `false` when it is not in the graph.
  bool beginStep(String id, {bool retry = false}) {
    if (!state.visibleIds.contains(id)) return false;
    _setStatus(id, retry ? StepStatus.retrying : StepStatus.active);
    return true;
  }

  /// Finishes step [id], as failed when [failed].
  void endStep(String id, {bool failed = false}) => _setStatus(id, failed ? StepStatus.failed : StepStatus.done);

  /// Marks the tour started.
  void startTour() => state = state.copyWith(isTouring: true);

  /// Shows the caption of tour chapter [step].
  void show(TourStep step) => state = state.copyWith(tourStep: step);

  /// Marks the tour ended and hides its caption.
  void endTour() => state = state.copyWith(isTouring: false, clearTourStep: true);

  /// Fits the whole graph, by default once the layout settles.
  void fit({bool awaitLayout = true}) => state = state.copyWith(
    camera: CameraRequest(version: state.camera.version + 1, awaitLayout: awaitLayout),
  );

  /// Centers step [id] once the layout settles.
  void focus(String id) => state = state.copyWith(
    camera: CameraRequest(version: state.camera.version + 1, focusId: id),
  );

  /// Zooms in on [fromId], then pans slowly to [toId] over [millis].
  void pan(String fromId, String toId, int millis) => state = state.copyWith(
    camera: CameraRequest(
      version: state.camera.version + 1,
      focusId: fromId,
      awaitLayout: false,
      panTo: toId,
      panMillis: millis,
    ),
  );

  void _setStatus(String id, StepStatus status) => state = state.copyWith(statuses: {...state.statuses, id: status});
}
