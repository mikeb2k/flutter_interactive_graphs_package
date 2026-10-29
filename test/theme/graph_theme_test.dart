import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final light = ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)));
  final dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: Brightness.dark),
  );

  // The theme as Theme.of hands it out: localized, so its text styles have sizes
  late ThemeData ambient;

  Future<GraphThemeData> resolve(WidgetTester tester, {required ThemeData theme, Widget Function(Widget)? wrap}) async {
    late GraphThemeData resolved;
    final probe = Builder(
      builder: (context) {
        ambient = Theme.of(context);
        resolved = GraphTheme.of(context);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(MaterialApp(theme: theme, home: wrap?.call(probe) ?? probe));
    // MaterialApp animates theme changes
    await tester.pumpAndSettle();
    return resolved;
  }

  testWidgets('derives colors and label text from the app theme', (tester) async {
    final resolved = await resolve(tester, theme: dark);
    final scheme = dark.colorScheme;

    expect(resolved.edgeColor, scheme.outline);
    expect(resolved.backEdgeColor, scheme.error);
    expect(resolved.labelTextColor, scheme.onSurface);
    expect(resolved.labelBackgroundColor, scheme.surfaceContainerHigh);
    expect(resolved.labelBorderColor, scheme.outlineVariant);
    expect(resolved.labelTextStyle, ambient.textTheme.labelMedium);
    expect(resolved.labelTextStyle.fontSize, isNotNull);
    expect(resolved, GraphThemeData.fromTheme(ambient));
  });

  testWidgets('follows the app when it switches between light and dark', (tester) async {
    final fromLight = await resolve(tester, theme: light);
    final fromDark = await resolve(tester, theme: dark);

    expect(fromLight.edgeColor, light.colorScheme.outline);
    expect(fromDark.edgeColor, dark.colorScheme.outline);
    expect(fromLight.edgeColor, isNot(fromDark.edgeColor));
  });

  testWidgets('a GraphThemeData theme extension overrides the derived colors', (tester) async {
    const custom = GraphThemeData(edgeColor: Color(0xFF00FF00));
    final resolved = await resolve(tester, theme: light.copyWith(extensions: [custom]));

    expect(resolved, custom);
  });

  testWidgets('a GraphTheme widget overrides the theme extension', (tester) async {
    const extension = GraphThemeData(edgeColor: Color(0xFF00FF00));
    const local = GraphThemeData(edgeColor: Color(0xFF0000FF));
    final resolved = await resolve(
      tester,
      theme: light.copyWith(extensions: [extension]),
      wrap: (child) => GraphTheme(data: local, child: child),
    );

    expect(resolved, local);
  });

  test('lerps between two themes', () {
    final from = GraphThemeData.fromTheme(light);
    final to = GraphThemeData.fromTheme(dark);

    expect(from.lerp(to, 0), from);
    expect(from.lerp(to, 1).edgeColor, to.edgeColor);
    expect(from.lerp(null, 0.5), from);
    expect(from.copyWith(edgeColor: to.edgeColor).edgeColor, to.edgeColor);

    const bold = TextStyle(fontWeight: FontWeight.bold);
    final withBold = from.copyWith(labelTextStyle: bold);
    expect(withBold.labelTextStyle, bold);
    expect(withBold, isNot(from));
    expect(withBold.hashCode, isNot(from.hashCode));
  });

  testWidgets('edges and labels draw in the theme colors and text style', (tester) async {
    final scheme = dark.colorScheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: dark,
        home: const Stack(
          children: [
            StyledEdge(
              details: EdgeDetails(edge: GraphEdge('A', 'B'), from: Offset.zero, to: Offset(200, 0)),
              label: 'ships',
            ),
          ],
        ),
      ),
    );

    expect(tester.widget<EdgeLine>(find.byType(EdgeLine)).style.color, scheme.outline);
    final text = tester.widget<Text>(find.text('ships'));
    expect(text.style?.color, scheme.onSurface);
    final context = tester.element(find.text('ships'));
    expect(text.style?.fontSize, Theme.of(context).textTheme.labelMedium?.fontSize);
    expect(text.style?.fontSize, isNotNull);
  });

  testWidgets('label style fields still win over the theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dark,
        home: const EdgeLabel(
          text: 'x',
          style: EdgeLabelStyle(textColor: Color(0xFF123456), fontSize: 20),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('x'));
    expect(text.style?.color, const Color(0xFF123456));
    expect(text.style?.fontSize, 20);
  });

  testWidgets('label text and border always have a value; a transparent border draws none', (tester) async {
    const theme = GraphThemeData();
    expect(theme.labelTextStyle.fontSize, 12);
    expect(GraphThemeData.fromColorScheme(dark.colorScheme).labelTextStyle.fontSize, 12);
    const none = Color(0x00000000);
    expect(theme.copyWith(labelBorderColor: none).labelBorderColor, none);

    await tester.pumpWidget(
      const GraphTheme(
        data: GraphThemeData(labelBorderColor: none),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EdgeLabel(text: 'x'),
        ),
      ),
    );
    final box = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    expect((box.decoration as BoxDecoration).border, isNull);
  });
}
