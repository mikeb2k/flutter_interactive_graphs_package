import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_graph.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_preset.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_test_copy.dart';
import 'package:interactive_graphs_example/features/stress_test/providers/stress_test_provider.dart';
import 'package:interactive_graphs_example/features/stress_test/views/stress_test_view.dart';
import 'package:interactive_graphs_example/features/stress_test/widgets/stress_node.dart';
import 'package:interactive_graphs_example/models/layout_algorithm.dart';
import 'package:interactive_graphs_example/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('StressGraph', () {
    test('is connected through a spanning path and has about 40 % extra edges', () {
      final generated = StressGraph.generate(nodeCount: 50, seed: 3);
      expect(generated.graph.nodes, hasLength(50));
      expect(generated.nodeData.keys.toSet(), generated.graph.nodes.keys.toSet());
      expect(generated.graph.edges.length, greaterThanOrEqualTo(49));
      expect(generated.graph.edges.length, lessThanOrEqualTo(49 + 20));
      expect(generated.graph.edges.every((edge) => edge.fromId != edge.toId), isTrue);
    });

    test('is deterministic per seed', () {
      final a = StressGraph.generate(nodeCount: 25, seed: 7);
      final b = StressGraph.generate(nodeCount: 25, seed: 7);
      expect(a, b);
      expect(a.graph.edges.map((edge) => edge.id), b.graph.edges.map((edge) => edge.id));
      expect(a.nodeData, b.nodeData);
    });
  });

  group('StressTestNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      container.listen(stressTestProvider, (_, _) {});
    });

    tearDown(() => container.dispose());

    test('starts with 100 nodes, force-directed layout and the toggles off', () {
      final state = container.read(stressTestProvider);
      expect(state.preset, StressPreset.medium);
      expect(state.stressGraph.graph.nodes, hasLength(100));
      expect(state.layoutAlgorithm, LayoutAlgorithm.forceDirected);
      expect(state.layoutConfig, isA<ForceDirectedLayoutConfig>());
      expect(state.showDebugBounds, isFalse);
      expect(state.batchedEdges, isFalse);
      expect(state.toolbarExpanded, isFalse);
    });

    test('selecting a preset generates a graph of that size', () {
      container.read(stressTestProvider.notifier).selectPreset(StressPreset.tiny);
      final state = container.read(stressTestProvider);
      expect(state.preset, StressPreset.tiny);
      expect(state.stressGraph.graph.nodes, hasLength(25));
    });

    test('regenerating advances the seed and keeps the size', () {
      final before = container.read(stressTestProvider);
      container.read(stressTestProvider.notifier).regenerate();
      final after = container.read(stressTestProvider);
      expect(after.seed, before.seed + 1);
      expect(after.stressGraph, isNot(before.stressGraph));
      expect(after.stressGraph.graph.nodes, hasLength(100));
    });

    test('switches layout and toggles', () {
      container.read(stressTestProvider.notifier)
        ..selectLayoutAlgorithm(LayoutAlgorithm.hierarchical)
        ..toggleDebugBounds()
        ..toggleBatchedEdges()
        ..toggleToolbar();
      final state = container.read(stressTestProvider);
      expect(state.layoutConfig, isA<HierarchicalLayoutConfig>());
      expect((state.layoutConfig as HierarchicalLayoutConfig).direction, LayoutDirection.horizontal);
      expect(state.showDebugBounds, isTrue);
      expect(state.batchedEdges, isTrue);
      expect(state.toolbarExpanded, isTrue);
    });
  });

  group('StressTestView', () {
    Future<void> pumpView(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => AppGraphTheme(child: child!),
            home: const StressTestView(),
          ),
        ),
      );
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    for (final (name, size) in [('phone', const Size(390, 844)), ('desktop', const Size(1400, 900))]) {
      testWidgets('lays out, regenerates and switches presets and edges on a $name', (tester) async {
        await pumpView(tester, size);
        await settle(tester);

        expect(find.byType(GraphViewer), findsOneWidget);
        expect(find.byType(StressNode), findsNWidgets(100));
        final viewer = tester.widget<GraphViewer>(find.byType(GraphViewer));
        expect(viewer.controller.hasFittedInitially, isTrue);
        expect(viewer.edgeBuilder, isNotNull);

        await tester.tap(find.text(StressTestCopy.preset(StressPreset.tiny)));
        await settle(tester);
        expect(find.byType(StressNode), findsNWidgets(25));
        final tiny = StressGraph.generate(nodeCount: 25, seed: 0).graph;
        expect(find.text(StressTestCopy.stats(25, tiny.edges.length)), findsOneWidget);

        await tester.tap(find.byTooltip(StressTestCopy.regenerate));
        await settle(tester);
        await tester.tap(find.text(StressTestCopy.batchedEdges));
        await tester.tap(find.text(StressTestCopy.layoutAlgorithm(LayoutAlgorithm.hierarchical)));
        await settle(tester);
        expect(tester.widget<GraphViewer>(find.byType(GraphViewer)).edgeBuilder, isNull);

        await tester.tap(find.byTooltip(StressTestCopy.zoomControls));
        await settle(tester);
        final controller = tester.widget<GraphViewer>(find.byType(GraphViewer)).controller;
        final scale = controller.scale;
        await tester.tap(find.byTooltip(StressTestCopy.zoomIn));
        await settle(tester);
        expect(controller.scale, greaterThan(scale));
        expect(find.text(StressTestCopy.zoomPercent(controller.scale)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('back pops the route', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => AppGraphTheme(child: child!),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(StressTestView.route()),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await settle(tester);
      expect(find.byType(StressTestView), findsOneWidget);
      await tester.tap(find.byTooltip(StressTestCopy.back));
      await settle(tester);
      expect(find.byType(StressTestView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
