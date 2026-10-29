import 'package:flutter/widgets.dart';
import 'package:interactive_graphs/src/edges/edge_geometry.dart';
import 'package:interactive_graphs/src/edges/edge_path.dart';
import 'package:interactive_graphs/src/edges/edge_style.dart';
import 'package:interactive_graphs/src/model/graph_edge.dart';
import 'package:interactive_graphs/src/theme/graph_theme.dart';
import 'package:interactive_graphs/src/viewer/registries.dart';
import 'package:meta/meta.dart';

/// What an `edgeBuilder` or `edgeStyle` callback gets: the edge, where it starts and ends (in the
/// edge layer's coordinates), the bend that fans it out from its twins, and its interaction state.
@immutable
final class EdgeDetails {
  /// Creates edge details.
  const EdgeDetails({
    required this.edge,
    required this.from,
    required this.to,
    this.bend,
    this.isSelected = false,
    this.isHovered = false,
  });

  /// The edge, with its classified [GraphEdge.type].
  final GraphEdge edge;

  /// Start point, on the start node's boundary or anchor.
  final Offset from;

  /// End point (the arrow tip), on the end node's boundary or anchor.
  final Offset to;

  /// Bend of a parallel edge or nested self loop (see `ParallelEdges`), `null` for single edges.
  final double? bend;

  /// Whether the edge is selected.
  final bool isSelected;

  /// Whether the pointer is over the edge; always `false` on touch.
  final bool isHovered;

  @override
  bool operator ==(Object other) =>
      other is EdgeDetails &&
      other.edge == edge &&
      other.from == from &&
      other.to == to &&
      other.bend == bend &&
      other.isSelected == isSelected &&
      other.isHovered == isHovered;

  @override
  int get hashCode => Object.hash(edge, from, to, bend, isSelected, isHovered);
}

/// Builds the widget of an edge. The widget fills the edge layer and draws in its coordinates;
/// use [EdgeLine] or [StyledEdge], or paint your own and call [EdgeHitScope.report].
typedef GraphEdgeBuilder = Widget Function(BuildContext context, EdgeDetails details);

/// Picks the [EdgeStyle] of an edge in the batched edge layer.
typedef EdgeStyleBuilder = EdgeStyle Function(EdgeDetails details);

/// Builds a custom label widget for [label].
typedef EdgeLabelBuilder = Widget Function(BuildContext context, String label);

/// Lets an edge widget report the path it draws, so taps and hover can hit it.
class EdgeHitScope extends InheritedWidget {
  /// Creates the scope. The viewer provides one around every built edge.
  @internal
  const EdgeHitScope({super.key, required this.edgeId, required this.registry, required super.child});

  /// Id of the edge being built.
  final String edgeId;

  /// Where paths are reported, `null` when edges are not interactive.
  final EdgeHitRegistry? registry;

  /// Reports [path] as the hit area of the edge [context] is building. A no-op outside a viewer or
  /// when edges are not interactive.
  static void report(BuildContext context, EdgePath path) {
    final scope = context.getInheritedWidgetOfExactType<EdgeHitScope>();
    scope?.registry?.report(scope.edgeId, path);
  }

  @override
  bool updateShouldNotify(EdgeHitScope oldWidget) => edgeId != oldWidget.edgeId || registry != oldWidget.registry;
}

/// Draws an edge in an [EdgeStyle], with an optional label, and reports its hit path.
class EdgeLine extends StatelessWidget {
  /// Creates an edge line.
  const EdgeLine({
    super.key,
    required this.details,
    this.style = const EdgeStyle(),
    this.label,
    this.labelPlacement = LabelPlacement.center,
    this.labelOffset,
    this.labelStyle = const EdgeLabelStyle(),
    this.labelBuilder,
    this.minLengthForLabel = 50,
  }) : assert(labelOffset == null || (labelOffset >= 0 && labelOffset <= 1)),
       assert(minLengthForLabel >= 0);

  /// The edge to draw.
  final EdgeDetails details;

  /// How to draw it.
  final EdgeStyle style;

  /// Label text, or `null` for none.
  final String? label;

  /// Where the label sits, unless [labelOffset] is given.
  final LabelPlacement labelPlacement;

  /// Label position along the edge, `0` to `1`; overrides [labelPlacement].
  final double? labelOffset;

  /// Look of the default label.
  final EdgeLabelStyle labelStyle;

  /// Custom label widget.
  final EdgeLabelBuilder? labelBuilder;

  /// Edges shorter than this hide their label.
  final double minLengthForLabel;

  @override
  Widget build(BuildContext context) {
    final path = style.createPath(details.edge, _bend(), details.from, details.to);
    EdgeHitScope.report(context, path);
    final line = CustomPaint(painter: _EdgePathPainter(path, style));
    final labelPosition = _labelPosition(path);
    if (labelPosition == null) return line;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        line,
        EdgeLabelPositioned(
          position: labelPosition,
          rotateWithEdge: labelStyle.rotateWithEdge,
          child: _labelWidget(context),
        ),
      ],
    );
  }

  double? _bend() {
    final bend = details.bend;
    if (bend == null || details.edge.isSelfLoop || style.shape.fansOut) return bend;
    return null;
  }

  EdgeLabelPosition? _labelPosition(EdgePath path) {
    final text = label;
    if (text == null || text.trim().isEmpty) return null;
    return path.labelPositionAt(labelOffset ?? labelPlacement.offset, minLength: minLengthForLabel);
  }

  Widget _labelWidget(BuildContext context) {
    final builder = labelBuilder;
    if (builder != null) return builder(context, label!);
    return EdgeLabel(text: label!, style: labelStyle);
  }
}

/// An edge in the default look: the theme's edge color, back edges dashed and faded, self loops
/// dashed in the back-edge color. Parallel edges fan out on their own.
class StyledEdge extends StatelessWidget {
  /// Creates a styled edge.
  const StyledEdge({
    super.key,
    required this.details,
    this.baseColor,
    this.backEdgeColor,
    this.strokeWidth = 3,
    this.shape = EdgeShape.auto,
    this.arrowSize = 16,
    this.arrowPainter = ArrowPainters.triangle,
    this.loopRadius = 40,
    this.label,
    this.labelPlacement = LabelPlacement.center,
    this.labelOffset,
    this.labelStyle = const EdgeLabelStyle(),
    this.labelBuilder,
    this.minLengthForLabel = 50,
  });

  /// The edge to draw.
  final EdgeDetails details;

  /// Color of forward and cross edges, [GraphThemeData.edgeColor] when `null`.
  final Color? baseColor;

  /// Color of self loops, [GraphThemeData.backEdgeColor] when `null`.
  final Color? backEdgeColor;

  /// Line width.
  final double strokeWidth;

  /// Geometry of the edge.
  final EdgeShape shape;

  /// Arrow head size.
  final double arrowSize;

  /// Arrow head painter.
  final ArrowPainter arrowPainter;

  /// Self loop radius.
  final double loopRadius;

  /// Label text, or `null` for none.
  final String? label;

  /// Where the label sits, unless [labelOffset] is given.
  final LabelPlacement labelPlacement;

  /// Label position along the edge, `0` to `1`.
  final double? labelOffset;

  /// Look of the default label.
  final EdgeLabelStyle labelStyle;

  /// Custom label widget.
  final EdgeLabelBuilder? labelBuilder;

  /// Edges shorter than this hide their label.
  final double minLengthForLabel;

  @override
  Widget build(BuildContext context) {
    final theme = GraphTheme.of(context);
    final style = EdgeStyle.styled(
      details.edge,
      baseColor: baseColor ?? theme.edgeColor,
      backEdgeColor: backEdgeColor ?? theme.backEdgeColor,
      strokeWidth: strokeWidth,
      shape: shape,
      arrowPainter: arrowPainter,
    ).copyWith(arrowSize: arrowSize, loopRadius: loopRadius);
    return EdgeLine(
      details: details,
      style: style,
      label: label,
      labelPlacement: labelPlacement,
      labelOffset: labelOffset,
      labelStyle: labelStyle,
      labelBuilder: labelBuilder,
      minLengthForLabel: minLengthForLabel,
    );
  }
}

/// The default edge label: text on a rounded, bordered background.
class EdgeLabel extends StatelessWidget {
  /// Creates a label.
  const EdgeLabel({super.key, required this.text, this.style = const EdgeLabelStyle()});

  /// Label text.
  final String text;

  /// Look of the label; `null` colors come from [GraphTheme].
  final EdgeLabelStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = GraphTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.backgroundColor ?? theme.labelBackgroundColor,
        borderRadius: BorderRadius.circular(style.cornerRadius),
        border: _border(theme),
      ),
      child: Padding(
        padding: style.padding,
        child: Text(
          text,
          maxLines: style.maxLines,
          overflow: style.overflow,
          style: TextStyle(
            color: style.textColor ?? theme.labelTextColor,
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
          ),
        ),
      ),
    );
  }

  Border? _border(GraphThemeData theme) {
    final color = style.borderColor ?? theme.labelBorderColor;
    if (color == null || style.borderWidth <= 0) return null;
    return Border.all(color: color, width: style.borderWidth);
  }
}

/// Centers [child] on [position] in the edge layer, turned along the edge when [rotateWithEdge].
class EdgeLabelPositioned extends StatelessWidget {
  /// Creates a positioned label.
  const EdgeLabelPositioned({super.key, required this.position, required this.child, this.rotateWithEdge = false});

  /// Where on the edge.
  final EdgeLabelPosition position;

  /// Turn with the edge, kept upright.
  final bool rotateWithEdge;

  /// The label.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomSingleChildLayout(delegate: _CenterAt(position.position), child: _rotated());

  Widget _rotated() {
    if (!rotateWithEdge) return child;
    return Transform.rotate(angle: EdgeGeometry.normalizeRotation(position.angle), child: child);
  }
}

class _CenterAt extends SingleChildLayoutDelegate {
  const _CenterAt(this.point);

  final Offset point;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size childSize) => point - childSize.center(Offset.zero);

  @override
  bool shouldRelayout(_CenterAt oldDelegate) => oldDelegate.point != point;
}

class _EdgePathPainter extends CustomPainter {
  const _EdgePathPainter(this.path, this.style);

  final EdgePath path;
  final EdgeStyle style;

  @override
  void paint(Canvas canvas, Size size) => EdgePainting.paint(canvas, path, style);

  @override
  bool shouldRepaint(_EdgePathPainter oldDelegate) => oldDelegate.path != path || oldDelegate.style != style;

  @override
  bool? hitTest(Offset position) => false;
}
