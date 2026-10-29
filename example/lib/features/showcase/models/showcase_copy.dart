import 'package:interactive_graphs_example/features/showcase/models/tour_text.dart';

/// Every text of the showcase screen and its guided tour, in one place for editing. The texts on
/// the order steps themselves live with their data in `ShowcaseSteps`.
abstract final class ShowcaseCopy {
  /// Screen title.
  static const String title = 'interactive_graphs';

  /// Starts the guided tour.
  static const String playTour = 'Play tour';

  /// Stops the guided tour.
  static const String stopTour = 'Stop tour';

  /// Opens the playground.
  static const String playground = 'Playground';

  /// Opens the stress test.
  static const String stressTest = 'Stress test';

  /// Menu with the other screens.
  static const String moreScreens = 'More screens';

  /// Theme toggle in dark mode.
  static const String switchToLight = 'Switch to light mode';

  /// Theme toggle in light mode.
  static const String switchToDark = 'Switch to dark mode';

  /// Plays the order through.
  static const String playOrder = 'Play order';

  /// Stops playing the order.
  static const String stopOrder = 'Stop order';

  /// Adds the next extra step.
  static const String addStep = 'Add step';

  /// Zooms out.
  static const String zoomOut = 'Zoom out';

  /// Zooms in.
  static const String zoomIn = 'Zoom in';

  /// Fits the graph into view.
  static const String fitGraph = 'Fit graph';

  /// Back to the plain order.
  static const String reset = 'Reset';

  /// Label of the status fact of an expanded step.
  static const String statusFact = 'Status';

  /// Step status: not started.
  static const String statusWaiting = 'Waiting';

  /// Step status: running.
  static const String statusActive = 'In progress';

  /// Step status: running again after a failure.
  static const String statusRetrying = 'Retrying';

  /// Step status: finished.
  static const String statusDone = 'Done';

  /// Step status: failed.
  static const String statusFailed = 'Needs attention';

  /// Layered layout, left to right.
  static const String layoutFlow = 'Flow';

  /// Layered layout, top to bottom.
  static const String layoutStack = 'Stack';

  /// Force-directed layout.
  static const String layoutOrganic = 'Organic';

  /// Custom circular layout.
  static const String layoutOrbit = 'Orbit';

  /// Curved edges.
  static const String edgeCurves = 'Curves';

  /// Right-angle edges.
  static const String edgeCircuit = 'Circuit';

  /// Straight edges.
  static const String edgeStraight = 'Straight';

  /// Subtitle under the screen title, for [steps] steps and [connections] edges.
  static String subtitle(int steps, int connections) => '$steps steps · $connections connections';

  /// Tour caption: opening.
  static const TourText intro = TourText('interactive_graphs', 'Directed graphs for Flutter', large: true);

  /// Tour caption: the graph grows.
  static const TourText grow = TourText('Live Layout', 'Every change is laid out and can be animated');

  /// Tour caption: nodes are widgets.
  static const TourText widgets = TourText('Nodes are widgets', 'Can be updated like any other widget');

  /// Tour caption: expanding nodes.
  static const TourText measured = TourText('Auto-measured layouts', 'Graph layout adapts to implicit node sizes');

  /// Tour caption: hierarchical layout.
  static const TourText layoutHierarchical = TourText('Layouts', 'Hierarchical');

  /// Tour caption: force-directed layout.
  static const TourText layoutForceDirected = TourText('Layouts', 'Force-directed');

  /// Tour caption: custom layout.
  static const TourText layoutCustom = TourText('Layouts', 'Custom LayoutProvider, e.g. circle');

  /// Tour caption: edge styles.
  static const TourText edges = TourText('Edge Customizations', 'Ports, labels, loops and parallel edges');

  /// Tour caption: selection, hover and drag.
  static const TourText interaction = TourText('Graph Interactions', 'Hover, select, drag');

  /// Tour caption: adding and removing nodes.
  static const TourText runtime = TourText('Change graph at runtime', 'Add, remove and update nodes and edges');

  /// Tour caption: camera moves.
  static const TourText camera = TourText('Zoom, pan, focus', 'Programmatic or user-driven');

  /// Tour caption: closing.
  static const TourText outro = TourText(
    'interactive_graphs',
    'github.com/BADIT-s-r-o/flutter_interactive_graphs_package',
    large: true,
  );
}
