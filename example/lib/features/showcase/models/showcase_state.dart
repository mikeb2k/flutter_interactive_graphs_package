import 'package:flutter/foundation.dart';
import 'package:interactive_graphs_example/features/showcase/models/camera_request.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_layout.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_steps.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_status.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_step.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_text.dart';

/// Everything the showcase shows besides node positions, driven by the controls and the guided
/// tour alike.
@immutable
class ShowcaseState {
  /// Creates a state.
  const ShowcaseState({
    required this.visibleIds,
    required this.homeLayout,
    required this.layout,
    required this.edgeStyle,
    required this.statuses,
    required this.expanded,
    required this.leaving,
    required this.entranceDelays,
    required this.camera,
    required this.isRunning,
    required this.isTouring,
    this.tourStep,
  });

  /// The full order in [layout], nothing running.
  factory ShowcaseState.initial({ShowcaseLayout layout = ShowcaseLayout.flow}) {
    final ids = ShowcaseSteps.orderIds;
    return ShowcaseState(
      visibleIds: ids,
      homeLayout: layout,
      layout: layout,
      edgeStyle: ShowcaseEdgeStyle.curves,
      statuses: const {},
      expanded: const {},
      leaving: const {},
      entranceDelays: ShowcaseSteps.staggered(ids),
      camera: CameraRequest.none,
      isRunning: false,
      isTouring: false,
    );
  }

  /// Steps in the graph, in the order they were added.
  final List<String> visibleIds;

  /// Layout that suits the window, which reset and the tour return to.
  final ShowcaseLayout homeLayout;

  /// Current layout.
  final ShowcaseLayout layout;

  /// Current edge shape.
  final ShowcaseEdgeStyle edgeStyle;

  /// Status of each step that has started, by node id.
  final Map<String, StepStatus> statuses;

  /// Expanded steps.
  final Set<String> expanded;

  /// Steps shrinking away before they leave the graph.
  final Set<String> leaving;

  /// Delay in milliseconds before each step pops in, to stagger steps that enter together.
  final Map<String, int> entranceDelays;

  /// Latest camera move.
  final CameraRequest camera;

  /// Whether the order is playing through on its own (the play button).
  final bool isRunning;

  /// Whether the guided tour is playing.
  final bool isTouring;

  /// Chapter of the tour on screen, `null` outside the tour.
  final TourStep? tourStep;

  /// Caption of [tourStep].
  TourText? get caption => tourStep?.caption;

  /// Status of step [id].
  StepStatus statusOf(String id) => statuses[id] ?? StepStatus.waiting;

  /// Whether any step is running, so that parcels flow along some edge.
  bool get hasRunningSteps => statuses.values.any((status) => status.isRunning);

  /// Returns a copy with the given fields replaced; [clearTourStep] removes the tour step.
  ShowcaseState copyWith({
    List<String>? visibleIds,
    ShowcaseLayout? homeLayout,
    ShowcaseLayout? layout,
    ShowcaseEdgeStyle? edgeStyle,
    Map<String, StepStatus>? statuses,
    Set<String>? expanded,
    Set<String>? leaving,
    Map<String, int>? entranceDelays,
    CameraRequest? camera,
    bool? isRunning,
    bool? isTouring,
    TourStep? tourStep,
    bool clearTourStep = false,
  }) => ShowcaseState(
    visibleIds: visibleIds ?? this.visibleIds,
    homeLayout: homeLayout ?? this.homeLayout,
    layout: layout ?? this.layout,
    edgeStyle: edgeStyle ?? this.edgeStyle,
    statuses: statuses ?? this.statuses,
    expanded: expanded ?? this.expanded,
    leaving: leaving ?? this.leaving,
    entranceDelays: entranceDelays ?? this.entranceDelays,
    camera: camera ?? this.camera,
    isRunning: isRunning ?? this.isRunning,
    isTouring: isTouring ?? this.isTouring,
    tourStep: clearTourStep ? null : tourStep ?? this.tourStep,
  );

  @override
  bool operator ==(Object other) =>
      other is ShowcaseState &&
      listEquals(other.visibleIds, visibleIds) &&
      other.homeLayout == homeLayout &&
      other.layout == layout &&
      other.edgeStyle == edgeStyle &&
      mapEquals(other.statuses, statuses) &&
      setEquals(other.expanded, expanded) &&
      setEquals(other.leaving, leaving) &&
      mapEquals(other.entranceDelays, entranceDelays) &&
      other.camera == camera &&
      other.isRunning == isRunning &&
      other.isTouring == isTouring &&
      other.tourStep == tourStep;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(visibleIds),
    homeLayout,
    layout,
    edgeStyle,
    Object.hashAllUnordered(statuses.entries.map((entry) => Object.hash(entry.key, entry.value))),
    Object.hashAllUnordered(expanded),
    Object.hashAllUnordered(leaving),
    Object.hashAllUnordered(entranceDelays.entries.map((entry) => Object.hash(entry.key, entry.value))),
    camera,
    isRunning,
    isTouring,
    tourStep,
  );
}
