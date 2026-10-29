/// Sizes and timings the showcase widgets and its camera share.
abstract final class ShowcaseMetrics {
  /// Width of a collapsed step card.
  static const double stepWidth = 220;

  /// Width of an expanded step card, also used to pick the focus zoom.
  static const double expandedStepWidth = 288;

  /// Room a tour caption takes at the top of the graph.
  static const double captionHeight = 132;

  /// Height of the floating toolbar.
  static const double toolbarHeight = 64;

  /// Gap around the floating toolbar.
  static const double toolbarMargin = 16;

  /// Room the floating toolbar takes at the bottom of the graph.
  static const double bottomInset = toolbarHeight + toolbarMargin;

  /// Time the camera gets to zoom in on the first node before a pan starts.
  static const Duration panLeadIn = Duration(milliseconds: 1000);

  /// Time a removed step takes to shrink away before it leaves the graph.
  static const Duration leaveDelay = Duration(milliseconds: 240);

  /// One turn of the parcels flowing along an edge.
  static const Duration flowPeriod = Duration(milliseconds: 1500);
}
