/// How the playground draws its edges. Back edges and self-loops always use [regular].
enum PlaygroundEdgeStyle {
  /// Straight, curved for back edges.
  regular,

  /// S-curve with horizontal ends.
  sCurve,

  /// Horizontal and vertical segments.
  rightAngle,
}
