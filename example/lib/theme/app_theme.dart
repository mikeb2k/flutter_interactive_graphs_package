import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:material_ui/material_ui.dart';

/// Light and dark Material themes of the example, a neutral charcoal palette (Kuiver's sample
/// theme). The only place besides [NodePalette] where raw colors are defined.
abstract final class AppTheme {
  /// Light theme.
  static ThemeData get light => _theme(
    const ColorScheme.light(
      primary: Color(0xFF2C2C3E),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE8E8F0),
      onPrimaryContainer: Color(0xFF1A1A28),
      secondary: Color(0xFF5E5E6E),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE3E3EC),
      onSecondaryContainer: Color(0xFF1B1B28),
      tertiary: Color(0xFF7E7E92),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE8E8F5),
      onTertiaryContainer: Color(0xFF2A2A3E),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFFCFCFF),
      onSurface: Color(0xFF1A1A1F),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF6F6FA),
      surfaceContainer: Color(0xFFF0F0F5),
      surfaceContainerHigh: Color(0xFFEAEAF0),
      surfaceContainerHighest: Color(0xFFE4E4EB),
      onSurfaceVariant: Color(0xFF46464F),
      outline: Color(0xFF767680),
      outlineVariant: Color(0xFFC7C7D0),
    ),
    NodePalette.light,
  );

  /// Dark theme.
  static ThemeData get dark => _theme(
    const ColorScheme.dark(
      primary: Color(0xFFCFCFE0),
      onPrimary: Color(0xFF2C2C3E),
      primaryContainer: Color(0xFF3E3E52),
      onPrimaryContainer: Color(0xFFE8E8F0),
      secondary: Color(0xFFC7C7D4),
      onSecondary: Color(0xFF30303E),
      secondaryContainer: Color(0xFF464655),
      onSecondaryContainer: Color(0xFFE3E3EC),
      tertiary: Color(0xFFCCCCDC),
      onTertiary: Color(0xFF353545),
      tertiaryContainer: Color(0xFF4C4C5E),
      onTertiaryContainer: Color(0xFFE8E8F5),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF1A1A1F),
      onSurface: Color(0xFFE3E3E8),
      surfaceContainerLowest: Color(0xFF141418),
      surfaceContainerLow: Color(0xFF202026),
      surfaceContainer: Color(0xFF26262C),
      surfaceContainerHigh: Color(0xFF303037),
      surfaceContainerHighest: Color(0xFF3B3B42),
      onSurfaceVariant: Color(0xFFC7C7D0),
      outline: Color(0xFF90909A),
      outlineVariant: Color(0xFF46464F),
    ),
    NodePalette.dark,
  );

  static ThemeData _theme(ColorScheme scheme, NodePalette palette) =>
      ThemeData(colorScheme: scheme, useMaterial3: true, extensions: [palette]);
}

/// Accent colors of the demo nodes, with a readable text color for each.
@immutable
class NodePalette extends ThemeExtension<NodePalette> {
  /// Creates a palette.
  const NodePalette({
    required this.pink,
    required this.onPink,
    required this.orange,
    required this.onOrange,
    required this.yellow,
    required this.onYellow,
    required this.green,
    required this.onGreen,
    required this.blue,
    required this.onBlue,
  });

  /// Palette of the light theme. Text colors keep at least 4.5:1 contrast.
  static const NodePalette light = NodePalette(
    pink: Color(0xFFFF6B9D),
    onPink: Color(0xFF3B0018),
    orange: Color(0xFFFFA06B),
    onOrange: Color(0xFF3A1600),
    yellow: Color(0xFFFFC93C),
    onYellow: Color(0xFF2B2000),
    green: Color(0xFF6BCF7F),
    onGreen: Color(0xFF00290C),
    blue: Color(0xFF6B9DFF),
    onBlue: Color(0xFF001A44),
  );

  /// Palette of the dark theme.
  static const NodePalette dark = light;

  /// Pink accent.
  final Color pink;

  /// Text on [pink].
  final Color onPink;

  /// Orange accent.
  final Color orange;

  /// Text on [orange].
  final Color onOrange;

  /// Yellow accent.
  final Color yellow;

  /// Text on [yellow].
  final Color onYellow;

  /// Green accent.
  final Color green;

  /// Text on [green].
  final Color onGreen;

  /// Blue accent.
  final Color blue;

  /// Text on [blue].
  final Color onBlue;

  /// The palette of the ambient theme.
  static NodePalette of(BuildContext context) => Theme.of(context).extension<NodePalette>() ?? light;

  @override
  NodePalette copyWith({
    Color? pink,
    Color? onPink,
    Color? orange,
    Color? onOrange,
    Color? yellow,
    Color? onYellow,
    Color? green,
    Color? onGreen,
    Color? blue,
    Color? onBlue,
  }) => NodePalette(
    pink: pink ?? this.pink,
    onPink: onPink ?? this.onPink,
    orange: orange ?? this.orange,
    onOrange: onOrange ?? this.onOrange,
    yellow: yellow ?? this.yellow,
    onYellow: onYellow ?? this.onYellow,
    green: green ?? this.green,
    onGreen: onGreen ?? this.onGreen,
    blue: blue ?? this.blue,
    onBlue: onBlue ?? this.onBlue,
  );

  @override
  NodePalette lerp(NodePalette? other, double t) {
    if (other == null) return this;
    return NodePalette(
      pink: Color.lerp(pink, other.pink, t)!,
      onPink: Color.lerp(onPink, other.onPink, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      onOrange: Color.lerp(onOrange, other.onOrange, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      onYellow: Color.lerp(onYellow, other.onYellow, t)!,
      green: Color.lerp(green, other.green, t)!,
      onGreen: Color.lerp(onGreen, other.onGreen, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      onBlue: Color.lerp(onBlue, other.onBlue, t)!,
    );
  }
}

/// Maps the Material color scheme onto the graph theme once, for every viewer below.
class AppGraphTheme extends StatelessWidget {
  /// Creates the mapping.
  const AppGraphTheme({super.key, required this.child});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GraphTheme(
      data: GraphThemeData(
        edgeColor: scheme.outline,
        backEdgeColor: scheme.error,
        labelTextColor: scheme.onSurface,
        labelBackgroundColor: scheme.surface.withValues(alpha: 0.9),
        labelBorderColor: scheme.outline.withValues(alpha: 0.3),
        debugGraphBoundsColor: scheme.error,
        debugViewportColor: scheme.primary,
      ),
      child: child,
    );
  }
}
