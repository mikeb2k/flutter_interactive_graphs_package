import 'package:material_ui/material_ui.dart';

/// Colors and label text style the package draws with.
///
/// Viewers follow the app's Material theme on their own: [GraphTheme.of] derives the colors from
/// the ambient [ColorScheme] and the label text from its [TextTheme] (see [GraphThemeData.fromTheme]),
/// so light and dark mode and custom schemes apply without any setup.
///
/// To change the graph's look, either add a [GraphThemeData] to the app theme:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     colorScheme: scheme,
///     extensions: [GraphThemeData.fromColorScheme(scheme).copyWith(backEdgeColor: scheme.tertiary)],
///   ),
/// )
/// ```
///
/// or wrap one part of the tree in a [GraphTheme].
@immutable
final class GraphThemeData extends ThemeExtension<GraphThemeData> {
  /// Creates theme data; every color defaults to a neutral light palette.
  const GraphThemeData({
    this.edgeColor = defaultEdgeColor,
    this.backEdgeColor = defaultBackEdgeColor,
    this.labelTextColor = defaultEdgeColor,
    this.labelBackgroundColor = const Color(0xE6FFFFFF),
    this.labelBorderColor = const Color(0x4D000000),
    this.labelTextStyle,
    this.debugGraphBoundsColor = const Color(0xFFFF0000),
    this.debugViewportColor = const Color(0xFF0000FF),
  });

  /// A neutral palette for dark backgrounds.
  const GraphThemeData.dark({
    this.edgeColor = const Color(0xFFE6E1E5),
    this.backEdgeColor = const Color(0xFFFF8A80),
    this.labelTextColor = const Color(0xFFE6E1E5),
    this.labelBackgroundColor = const Color(0xE6202124),
    this.labelBorderColor = const Color(0x4DFFFFFF),
    this.labelTextStyle,
    this.debugGraphBoundsColor = const Color(0xFFFF5252),
    this.debugViewportColor = const Color(0xFF448AFF),
  });

  /// The graph look derived from [scheme]: edges in `outline` (back edges faded), self loops in
  /// `error`, labels in `onSurface` on `surfaceContainerHigh` with an `outlineVariant` border, and
  /// [labelTextStyle] as the label text.
  factory GraphThemeData.fromColorScheme(ColorScheme scheme, {TextStyle? labelTextStyle}) => GraphThemeData(
    edgeColor: scheme.outline,
    backEdgeColor: scheme.error,
    labelTextColor: scheme.onSurface,
    labelBackgroundColor: scheme.surfaceContainerHigh,
    labelBorderColor: scheme.outlineVariant,
    labelTextStyle: labelTextStyle,
    debugGraphBoundsColor: scheme.error,
    debugViewportColor: scheme.primary,
  );

  /// The graph look derived from [theme]: [GraphThemeData.fromColorScheme] of its color scheme,
  /// with `textTheme.labelMedium` as the label text.
  factory GraphThemeData.fromTheme(ThemeData theme) =>
      GraphThemeData.fromColorScheme(theme.colorScheme, labelTextStyle: theme.textTheme.labelMedium);

  /// Edge color of the neutral light palette and of `EdgeStyle`.
  static const Color defaultEdgeColor = Color(0xFF000000);

  /// Back-edge and self-loop color of the neutral light palette.
  static const Color defaultBackEdgeColor = Color(0xFFFF6B6B);

  /// Color of forward and cross edges.
  final Color edgeColor;

  /// Color of self loops; back edges use a faded [edgeColor].
  final Color backEdgeColor;

  /// Edge label text color.
  final Color labelTextColor;

  /// Edge label background.
  final Color labelBackgroundColor;

  /// Edge label border, or `null` for none.
  final Color? labelBorderColor;

  /// Base text style of edge labels (font, size, weight), 12 px when `null`. [labelTextColor] and
  /// the fields of `EdgeLabelStyle` are applied on top.
  final TextStyle? labelTextStyle;

  /// Graph bounds drawn by `GraphViewerConfig.showDebugBounds`.
  final Color debugGraphBoundsColor;

  /// Viewport outline drawn by `GraphViewerConfig.showDebugBounds`.
  final Color debugViewportColor;

  @override
  GraphThemeData copyWith({
    Color? edgeColor,
    Color? backEdgeColor,
    Color? labelTextColor,
    Color? labelBackgroundColor,
    Color? labelBorderColor,
    TextStyle? labelTextStyle,
    Color? debugGraphBoundsColor,
    Color? debugViewportColor,
  }) => GraphThemeData(
    edgeColor: edgeColor ?? this.edgeColor,
    backEdgeColor: backEdgeColor ?? this.backEdgeColor,
    labelTextColor: labelTextColor ?? this.labelTextColor,
    labelBackgroundColor: labelBackgroundColor ?? this.labelBackgroundColor,
    labelBorderColor: labelBorderColor ?? this.labelBorderColor,
    labelTextStyle: labelTextStyle ?? this.labelTextStyle,
    debugGraphBoundsColor: debugGraphBoundsColor ?? this.debugGraphBoundsColor,
    debugViewportColor: debugViewportColor ?? this.debugViewportColor,
  );

  @override
  GraphThemeData lerp(GraphThemeData? other, double t) {
    if (other == null) return this;
    return GraphThemeData(
      edgeColor: Color.lerp(edgeColor, other.edgeColor, t)!,
      backEdgeColor: Color.lerp(backEdgeColor, other.backEdgeColor, t)!,
      labelTextColor: Color.lerp(labelTextColor, other.labelTextColor, t)!,
      labelBackgroundColor: Color.lerp(labelBackgroundColor, other.labelBackgroundColor, t)!,
      labelBorderColor: Color.lerp(labelBorderColor, other.labelBorderColor, t),
      labelTextStyle: TextStyle.lerp(labelTextStyle, other.labelTextStyle, t),
      debugGraphBoundsColor: Color.lerp(debugGraphBoundsColor, other.debugGraphBoundsColor, t)!,
      debugViewportColor: Color.lerp(debugViewportColor, other.debugViewportColor, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GraphThemeData &&
      other.edgeColor == edgeColor &&
      other.backEdgeColor == backEdgeColor &&
      other.labelTextColor == labelTextColor &&
      other.labelBackgroundColor == labelBackgroundColor &&
      other.labelBorderColor == labelBorderColor &&
      other.labelTextStyle == labelTextStyle &&
      other.debugGraphBoundsColor == debugGraphBoundsColor &&
      other.debugViewportColor == debugViewportColor;

  @override
  int get hashCode => Object.hash(
    edgeColor,
    backEdgeColor,
    labelTextColor,
    labelBackgroundColor,
    labelBorderColor,
    labelTextStyle,
    debugGraphBoundsColor,
    debugViewportColor,
  );
}

/// Overrides the [GraphThemeData] for the graph widgets below it.
///
/// Optional: without one, graphs follow the app's [Theme] (see [GraphThemeData]).
class GraphTheme extends InheritedTheme {
  /// Creates a graph theme.
  const GraphTheme({super.key, required this.data, required super.child});

  /// The theme data.
  final GraphThemeData data;

  /// The graph theme for [context]: the closest [GraphTheme], else the [GraphThemeData] extension
  /// of the ambient [Theme], else [GraphThemeData.fromTheme] of that theme.
  static GraphThemeData of(BuildContext context) {
    final local = context.dependOnInheritedWidgetOfExactType<GraphTheme>();
    if (local != null) return local.data;
    final theme = Theme.of(context);
    return theme.extension<GraphThemeData>() ?? GraphThemeData.fromTheme(theme);
  }

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
    this.fontSize,
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

  /// Font size, the theme's label text size when `null`.
  final double? fontSize;

  /// Font weight; `null` keeps the weight of [GraphThemeData.labelTextStyle] (the theme's
  /// `labelMedium` by default).
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
