import 'package:flutter/widgets.dart';

/// Colors and label style the package draws with.
///
/// The package depends on `widgets` only, so it cannot read a Material `ColorScheme`; map your
/// app theme once with a [GraphTheme] above the viewer:
///
/// ```dart
/// GraphTheme(
///   data: GraphThemeData(
///     edgeColor: scheme.onSurfaceVariant,
///     backEdgeColor: scheme.tertiary,
///     labelTextColor: scheme.onSurface,
///     labelBackgroundColor: scheme.surfaceContainerHigh,
///     labelBorderColor: scheme.outlineVariant,
///   ),
///   child: GraphViewer(...),
/// )
/// ```
@immutable
final class GraphThemeData {
  /// Creates theme data; every color defaults to the light palette.
  const GraphThemeData({
    this.edgeColor = defaultEdgeColor,
    this.backEdgeColor = defaultBackEdgeColor,
    this.labelTextColor = defaultEdgeColor,
    this.labelBackgroundColor = const Color(0xE6FFFFFF),
    this.labelBorderColor = const Color(0x4D000000),
    this.debugGraphBoundsColor = const Color(0xFFFF0000),
    this.debugViewportColor = const Color(0xFF0000FF),
  });

  /// A palette for dark backgrounds.
  const GraphThemeData.dark({
    this.edgeColor = const Color(0xFFE6E1E5),
    this.backEdgeColor = const Color(0xFFFF8A80),
    this.labelTextColor = const Color(0xFFE6E1E5),
    this.labelBackgroundColor = const Color(0xE6202124),
    this.labelBorderColor = const Color(0x4DFFFFFF),
    this.debugGraphBoundsColor = const Color(0xFFFF5252),
    this.debugViewportColor = const Color(0xFF448AFF),
  });

  /// Edge color of the light palette and of `EdgeStyle`.
  static const Color defaultEdgeColor = Color(0xFF000000);

  /// Back-edge and self-loop color of the light palette.
  static const Color defaultBackEdgeColor = Color(0xFFFF6B6B);

  /// Color of forward and cross edges.
  final Color edgeColor;

  /// Color of self loops; back edges use a faded [edgeColor].
  final Color backEdgeColor;

  /// Edge label text.
  final Color labelTextColor;

  /// Edge label background.
  final Color labelBackgroundColor;

  /// Edge label border, or `null` for none.
  final Color? labelBorderColor;

  /// Graph bounds drawn by `GraphViewerConfig.showDebugBounds`.
  final Color debugGraphBoundsColor;

  /// Viewport outline drawn by `GraphViewerConfig.showDebugBounds`.
  final Color debugViewportColor;

  /// Returns a copy with the given fields replaced.
  GraphThemeData copyWith({
    Color? edgeColor,
    Color? backEdgeColor,
    Color? labelTextColor,
    Color? labelBackgroundColor,
    Color? labelBorderColor,
    Color? debugGraphBoundsColor,
    Color? debugViewportColor,
  }) => GraphThemeData(
    edgeColor: edgeColor ?? this.edgeColor,
    backEdgeColor: backEdgeColor ?? this.backEdgeColor,
    labelTextColor: labelTextColor ?? this.labelTextColor,
    labelBackgroundColor: labelBackgroundColor ?? this.labelBackgroundColor,
    labelBorderColor: labelBorderColor ?? this.labelBorderColor,
    debugGraphBoundsColor: debugGraphBoundsColor ?? this.debugGraphBoundsColor,
    debugViewportColor: debugViewportColor ?? this.debugViewportColor,
  );

  @override
  bool operator ==(Object other) =>
      other is GraphThemeData &&
      other.edgeColor == edgeColor &&
      other.backEdgeColor == backEdgeColor &&
      other.labelTextColor == labelTextColor &&
      other.labelBackgroundColor == labelBackgroundColor &&
      other.labelBorderColor == labelBorderColor &&
      other.debugGraphBoundsColor == debugGraphBoundsColor &&
      other.debugViewportColor == debugViewportColor;

  @override
  int get hashCode => Object.hash(
    edgeColor,
    backEdgeColor,
    labelTextColor,
    labelBackgroundColor,
    labelBorderColor,
    debugGraphBoundsColor,
    debugViewportColor,
  );
}

/// Provides [GraphThemeData] to the graph widgets below it.
class GraphTheme extends InheritedTheme {
  /// Creates a graph theme.
  const GraphTheme({super.key, required this.data, required super.child});

  /// The theme data.
  final GraphThemeData data;

  /// The closest [GraphThemeData], or the light defaults.
  static GraphThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GraphTheme>()?.data ?? const GraphThemeData();

  @override
  Widget wrap(BuildContext context, Widget child) => GraphTheme(data: data, child: child);

  @override
  bool updateShouldNotify(GraphTheme oldWidget) => data != oldWidget.data;
}

/// Look of an edge label. `null` colors come from [GraphTheme].
@immutable
final class EdgeLabelStyle {
  /// Creates a label style.
  const EdgeLabelStyle({
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.fontSize = 12,
    this.fontWeight,
    this.padding = const EdgeInsets.all(4),
    this.borderWidth = 1,
    this.cornerRadius = 4,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.rotateWithEdge = false,
  });

  /// Text color, [GraphThemeData.labelTextColor] when `null`.
  final Color? textColor;

  /// Background, [GraphThemeData.labelBackgroundColor] when `null`.
  final Color? backgroundColor;

  /// Border, [GraphThemeData.labelBorderColor] when `null`.
  final Color? borderColor;

  /// Font size.
  final double fontSize;

  /// Font weight, the ambient one when `null`.
  final FontWeight? fontWeight;

  /// Padding around the text.
  final EdgeInsets padding;

  /// Border width.
  final double borderWidth;

  /// Corner radius.
  final double cornerRadius;

  /// Maximum number of lines.
  final int maxLines;

  /// Overflow of long labels.
  final TextOverflow overflow;

  /// Whether the label turns with the edge (kept upright).
  final bool rotateWithEdge;

  /// Returns a copy with the given fields replaced.
  EdgeLabelStyle copyWith({
    Color? textColor,
    Color? backgroundColor,
    Color? borderColor,
    double? fontSize,
    FontWeight? fontWeight,
    EdgeInsets? padding,
    double? borderWidth,
    double? cornerRadius,
    int? maxLines,
    TextOverflow? overflow,
    bool? rotateWithEdge,
  }) => EdgeLabelStyle(
    textColor: textColor ?? this.textColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    fontSize: fontSize ?? this.fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
    padding: padding ?? this.padding,
    borderWidth: borderWidth ?? this.borderWidth,
    cornerRadius: cornerRadius ?? this.cornerRadius,
    maxLines: maxLines ?? this.maxLines,
    overflow: overflow ?? this.overflow,
    rotateWithEdge: rotateWithEdge ?? this.rotateWithEdge,
  );

  @override
  bool operator ==(Object other) =>
      other is EdgeLabelStyle &&
      other.textColor == textColor &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.fontSize == fontSize &&
      other.fontWeight == fontWeight &&
      other.padding == padding &&
      other.borderWidth == borderWidth &&
      other.cornerRadius == cornerRadius &&
      other.maxLines == maxLines &&
      other.overflow == overflow &&
      other.rotateWithEdge == rotateWithEdge;

  @override
  int get hashCode => Object.hash(
    textColor,
    backgroundColor,
    borderColor,
    fontSize,
    fontWeight,
    padding,
    borderWidth,
    cornerRadius,
    maxLines,
    overflow,
    rotateWithEdge,
  );
}
