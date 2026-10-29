import 'package:interactive_graphs_example/features/showcase/models/showcase_copy.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_text.dart';

/// Chapters of the guided tour, in the order it plays them.
enum TourStep {
  /// Opening title.
  intro,

  /// The graph grows one step at a time.
  grow,

  /// The order plays through while the camera pans along.
  widgets,

  /// Steps expand and the layout follows their size.
  measured,

  /// Hierarchical layout.
  layoutHierarchical,

  /// Force-directed layout.
  layoutForceDirected,

  /// Custom circular layout.
  layoutCustom,

  /// Edge styles.
  edges,

  /// Selection, hover and drag.
  interaction,

  /// Steps are added and removed.
  runtime,

  /// Focus and fit.
  camera,

  /// Closing title.
  outro;

  /// Caption shown during this chapter.
  TourText get caption => switch (this) {
    TourStep.intro => ShowcaseCopy.intro,
    TourStep.grow => ShowcaseCopy.grow,
    TourStep.widgets => ShowcaseCopy.widgets,
    TourStep.measured => ShowcaseCopy.measured,
    TourStep.layoutHierarchical => ShowcaseCopy.layoutHierarchical,
    TourStep.layoutForceDirected => ShowcaseCopy.layoutForceDirected,
    TourStep.layoutCustom => ShowcaseCopy.layoutCustom,
    TourStep.edges => ShowcaseCopy.edges,
    TourStep.interaction => ShowcaseCopy.interaction,
    TourStep.runtime => ShowcaseCopy.runtime,
    TourStep.camera => ShowcaseCopy.camera,
    TourStep.outro => ShowcaseCopy.outro,
  };
}
