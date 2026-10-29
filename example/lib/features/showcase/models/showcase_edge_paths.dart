import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_layout.dart';
import 'package:material_ui/material_ui.dart';

/// Paths of the showcase edges in each [ShowcaseEdgeStyle], built from the same `EdgePathFactory`
/// the built-in edges use.
abstract final class ShowcaseEdgePaths {
  /// Line width of the showcase edges.
  static const double strokeWidth = 2;

  /// Radius of self loops.
  static const double loopRadius = 30;

  /// Dash length of loops.
  static const double dashLength = 6;

  /// Gap between the dashes of loops.
  static const double gapLength = 5;

  /// Length of one dash and gap.
  static const double dashPeriod = dashLength + gapLength;

  /// Corner radius of right-angle edges.
  static const double cornerRadius = 12;

  /// How far the S-curve of vertical edges stops short of the arrow tip.
  static const double curveShorten = 4;

  /// The path of the edge in [details] in [style].
  ///
  /// Loops and back edges always curve, and parallel edges fan out wider than the default to give
  /// their labels room. Otherwise curves follow the anchor sides: S-curves between top and bottom
  /// or left and right ports, a slight bend without ports.
  static EdgePath create(EdgeDetails details, ShowcaseEdgeStyle style) {
    final EdgeDetails(:edge, :from, :to, :bend) = details;
    final fromSide = AnchorSide.fromAnchorId(edge.fromAnchor);
    final toSide = AnchorSide.fromAnchorId(edge.toAnchor);
    if (edge.isSelfLoop) {
      return EdgePathFactory.selfLoop(from, to, loopRadius: loopRadius, strokeWidth: strokeWidth, bend: bend ?? 0);
    }
    if (bend != null && bend != 0) return EdgePathFactory.curved(from, to, strokeWidth: strokeWidth, bend: bend * 3);
    if (edge.type == EdgeType.back) return EdgePathFactory.curved(from, to, strokeWidth: strokeWidth, bend: 0.3);
    return switch (style) {
      ShowcaseEdgeStyle.straight => EdgePathFactory.straight(from, to, strokeWidth: strokeWidth),
      ShowcaseEdgeStyle.circuit => EdgePathFactory.rightAngle(
        from,
        to,
        RightAngleRouting.fromAnchorSides(fromSide, toSide),
        strokeWidth: strokeWidth,
      ),
      ShowcaseEdgeStyle.curves => switch (fromSide) {
        AnchorSide.top || AnchorSide.bottom => verticalSCurve(from, to),
        AnchorSide.left || AnchorSide.right => EdgePathFactory.orthogonal(from, to, strokeWidth: strokeWidth),
        null => EdgePathFactory.curved(from, to, strokeWidth: strokeWidth, bend: 0.12),
      },
    };
  }

  /// S-curve with vertical tangents, the top to bottom twin of `EdgePathFactory.orthogonal`.
  static OrthogonalEdgePath verticalSCurve(Offset from, Offset to) {
    final reach = (to.dy - from.dy) * 0.5;
    final control1 = from.translate(0, reach);
    final control2 = to.translate(0, -reach);
    final direction = EdgeGeometry.normalize(to - control2) ?? EdgeGeometry.normalize(to - from) ?? Offset.zero;
    return OrthogonalEdgePath(
      from: from,
      to: to,
      controlPoint1: control1,
      controlPoint2: control2,
      pathEndpoint: to - direction * curveShorten,
      length: EdgeGeometry.cubicLength(from, control1, control2, to),
      curveFactor: 0.5,
    );
  }
}
