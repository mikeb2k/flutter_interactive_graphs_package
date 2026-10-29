import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/showcase/models/edge_state.dart';
import 'package:interactive_graphs_example/features/showcase/models/graph_focus.dart';
import 'package:interactive_graphs_example/features/showcase/models/orbit_layout.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_copy.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_layout.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_state.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_steps.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_graph.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_status.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_pacer.dart';
import 'package:interactive_graphs_example/features/showcase/models/tour_step.dart';
import 'package:interactive_graphs_example/features/showcase/providers/showcase_provider.dart';
import 'package:interactive_graphs_example/features/showcase/views/showcase_view.dart';
import 'package:interactive_graphs_example/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(showcaseProvider, (_, _) {});
    return container;
  }

  group('ShowcaseNotifier', () {
    test('starts with the full order, nothing running', () {
      final state = createContainer().read(showcaseProvider);
      expect(state.visibleIds, ShowcaseSteps.orderIds);
      expect(state.layout, ShowcaseLayout.flow);
      expect(state.statuses, isEmpty);
      expect(state.isTouring, isFalse);
      expect(state.caption, isNull);
    });

    test('adopts the home layout once and restores to it', () {
      final container = createContainer();
      final notifier = container.read(showcaseProvider.notifier)
        ..setHomeLayout(ShowcaseLayout.stack, apply: true)
        ..selectLayout(ShowcaseLayout.orbit)
        ..setHomeLayout(ShowcaseLayout.flow);
      expect(container.read(showcaseProvider).layout, ShowcaseLayout.orbit);

      notifier.restore(ShowcaseSteps.orderIds.take(3).toList());
      final state = container.read(showcaseProvider);
      expect(state.layout, ShowcaseLayout.flow);
      expect(state.visibleIds, ['order', 'payment', 'stock']);
      expect(state.entranceDelays, {'order': 0, 'payment': 70, 'stock': 140});
    });

    test('expanding focuses the step, collapsing refits', () {
      final container = createContainer();
      final notifier = container.read(showcaseProvider.notifier)..toggleExpanded('payment');
      var state = container.read(showcaseProvider);
      expect(state.expanded, {'payment'});
      expect(state.camera.focusId, 'payment');
      final version = state.camera.version;

      notifier.toggleExpanded('payment');
      state = container.read(showcaseProvider);
      expect(state.expanded, isEmpty);
      expect(state.camera.focusId, isNull);
      expect(state.camera.version, version + 1);
    });

    test('adds extra steps in order and removes steps except the order', () {
      final container = createContainer();
      final notifier = container.read(showcaseProvider.notifier)
        ..addStep()
        ..addStep();
      expect(container.read(showcaseProvider).visibleIds.skip(9), ['gift', 'quality']);

      expect(notifier.startLeaving('order'), isFalse);
      expect(notifier.startLeaving('gift'), isTrue);
      expect(notifier.startLeaving('gift'), isFalse);
      expect(container.read(showcaseProvider).leaving, {'gift'});
      notifier.dropStep('gift');
      final state = container.read(showcaseProvider);
      expect(state.visibleIds, isNot(contains('gift')));
      expect(state.leaving, isEmpty);
    });

    test('steps run only when visible', () {
      final container = createContainer();
      final notifier = container.read(showcaseProvider.notifier);
      expect(notifier.beginStep('gift'), isFalse);
      expect(notifier.beginStep('payment', retry: true), isTrue);
      expect(container.read(showcaseProvider).hasRunningSteps, isTrue);
      notifier.endStep('payment', failed: true);
      expect(container.read(showcaseProvider).statusOf('payment'), StepStatus.failed);
      expect(container.read(showcaseProvider).hasRunningSteps, isFalse);
    });

    test('tour chapters set the caption until the tour ends', () {
      final container = createContainer();
      final notifier = container.read(showcaseProvider.notifier)
        ..startTour()
        ..show(TourStep.intro);
      expect(container.read(showcaseProvider).caption, ShowcaseCopy.intro);
      notifier.endTour();
      final state = container.read(showcaseProvider);
      expect(state.isTouring, isFalse);
      expect(state.tourStep, isNull);
    });

    test('pan asks for an immediate camera move', () {
      final container = createContainer();
      container.read(showcaseProvider.notifier).pan('order', 'delivered', 9000);
      final camera = container.read(showcaseProvider).camera;
      expect(camera.focusId, 'order');
      expect(camera.panTo, 'delivered');
      expect(camera.awaitLayout, isFalse);
    });
  });

  group('models', () {
    test('graph anchors follow the layout and loops come last', () {
      final flow = StepGraph.build(ShowcaseSteps.orderIds, ShowcaseLayout.flow);
      expect(flow.nodes, hasLength(9));
      expect(flow.edges, hasLength(12));
      expect(flow.edge('order->payment')?.fromAnchor, 'right');
      expect(flow.edge('courier->hub')?.toAnchor, 'top');
      expect(flow.edges.last.id, 'courier->hub');
      expect(flow.edge('payment->payment')?.fromAnchor, isNull);

      final stack = StepGraph.build(ShowcaseSteps.orderIds, ShowcaseLayout.stack);
      expect(stack.edge('order->payment')?.fromAnchor, 'bottom');
      expect(StepGraph.ports(stack)['hub'], containsAll(['top', 'bottom', 'right']));

      final organic = StepGraph.build([...ShowcaseSteps.orderIds, 'gift'], ShowcaseLayout.organic);
      expect(organic.edges, hasLength(14));
      expect(StepGraph.ports(organic), isEmpty);
    });

    test('orbit layout puts every node on one ring', () {
      final graph = StepGraph.build(ShowcaseSteps.orderIds, ShowcaseLayout.orbit);
      final laid = OrbitLayout.run(graph, const LayoutConfig.custom(OrbitLayout.run, canvasSize: Size(800, 600)));
      const center = Offset(400, 300);
      for (final node in laid.nodes.values) {
        final d = node.position - center;
        final r = Offset(d.dx, d.dy / OrbitLayout.squash).distance;
        expect(r, closeTo(OrbitLayout.nodeArc * 9 / (2 * math.pi), 0.01));
      }
      expect(laid.edge('courier->hub')?.type, EdgeType.back);
    });

    test('edge state follows the step statuses', () {
      const edge = GraphEdge('order', 'payment');
      expect(EdgeState.of(edge, const {}), EdgeState.idle);
      expect(EdgeState.of(edge, const {'order': StepStatus.done, 'payment': StepStatus.active}), EdgeState.flowing);
      expect(EdgeState.of(edge, const {'order': StepStatus.done, 'payment': StepStatus.done}), EdgeState.lit);
      const loop = GraphEdge('payment', 'payment');
      expect(EdgeState.of(loop, const {'payment': StepStatus.retrying}), EdgeState.flowing);
      const back = GraphEdge('courier', 'hub', type: EdgeType.back);
      expect(EdgeState.of(back, const {'courier': StepStatus.failed, 'hub': StepStatus.active}), EdgeState.flowing);
      expect(EdgeState.of(back, const {'courier': StepStatus.done, 'hub': StepStatus.done}), EdgeState.idle);
    });

    test('focus dims what is outside the neighbourhood', () {
      final graph = StepGraph.build(ShowcaseSteps.orderIds, ShowcaseLayout.flow);
      final interaction = GraphInteraction()..select('pack');
      addTearDown(interaction.dispose);
      final focus = GraphFocus.of(interaction, graph.edges);
      expect(focus.dimsNode('pack'), isFalse);
      expect(focus.dimsNode('hub'), isFalse);
      expect(focus.dimsNode('order'), isTrue);
      expect(focus.dimsEdge(graph.edge('order->payment')!), isTrue);
      expect(const GraphFocus().dimsNode('order'), isFalse);
    });

    test('a cancelled pacer fails pending and later waits', () async {
      final pacer = TourPacer();
      final pending = pacer.wait(const Duration(seconds: 10));
      pacer.cancel();
      await expectLater(pending, throwsA(isA<TourCancelled>()));
      await expectLater(pacer.wait(Duration.zero), throwsA(isA<TourCancelled>()));
    });

    test('the state copies and compares by value', () {
      final state = ShowcaseState.initial();
      expect(state.copyWith(), state);
      expect(state.copyWith(tourStep: TourStep.outro).copyWith(clearTourStep: true), state);
      expect(state.copyWith(expanded: {'hub'}), isNot(state));
    });
  });

  group('ShowcaseView', () {
    Future<void> pumpFor(WidgetTester tester, Duration duration) async {
      final end = tester.binding.clock.now().add(duration);
      while (tester.binding.clock.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<ProviderContainer> pumpView(WidgetTester tester, Size size) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => AppGraphTheme(child: child!),
            home: const ShowcaseView(),
          ),
        ),
      );
      await pumpFor(tester, const Duration(seconds: 2));
      return ProviderScope.containerOf(tester.element(find.byType(ShowcaseView)));
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('phone: stacks the order, adds a step and plays the order through', (tester) async {
      final container = await pumpView(tester, const Size(390, 844));
      expect(find.byType(GraphViewer), findsOneWidget);
      expect(container.read(showcaseProvider).layout, ShowcaseLayout.stack);
      expect(find.text(ShowcaseCopy.subtitle(9, 12)), findsOneWidget);

      await tester.tap(find.byTooltip(ShowcaseCopy.addStep));
      await pumpFor(tester, const Duration(seconds: 2));
      expect(find.text(ShowcaseCopy.subtitle(10, 14)), findsOneWidget);

      await tester.tap(find.byTooltip(ShowcaseCopy.playOrder));
      await pumpFor(tester, const Duration(seconds: 1));
      expect(container.read(showcaseProvider).isRunning, isTrue);
      await pumpFor(tester, const Duration(seconds: 12));
      final state = container.read(showcaseProvider);
      expect(state.isRunning, isFalse);
      expect(state.statusOf('delivered'), StepStatus.done);
      expect(state.statusOf('gift'), StepStatus.done);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    testWidgets('phone: the tour shows captions and stops on demand', (tester) async {
      final container = await pumpView(tester, const Size(390, 844));
      await tester.tap(find.byTooltip(ShowcaseCopy.playTour));
      await pumpFor(tester, const Duration(milliseconds: 1500));
      expect(find.text(ShowcaseCopy.intro.body), findsOneWidget);
      expect(container.read(showcaseProvider).visibleIds, hasLength(3));

      await pumpFor(tester, const Duration(seconds: 3));
      expect(container.read(showcaseProvider).tourStep, TourStep.grow);
      expect(container.read(showcaseProvider).visibleIds, hasLength(9));

      await tester.tap(find.byTooltip(ShowcaseCopy.stopTour));
      await pumpFor(tester, const Duration(seconds: 1));
      final state = container.read(showcaseProvider);
      expect(state.isTouring, isFalse);
      expect(state.caption, isNull);
      expect(find.text(ShowcaseCopy.intro.body), findsNothing);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    testWidgets('desktop: flows left to right, expands a step and switches layouts', (tester) async {
      final container = await pumpView(tester, const Size(1400, 900));
      expect(find.byType(GraphViewer), findsOneWidget);
      expect(container.read(showcaseProvider).layout, ShowcaseLayout.flow);
      expect(find.text(ShowcaseCopy.playTour), findsOneWidget);

      await tester.tap(find.text('Payment'));
      await pumpFor(tester, const Duration(seconds: 2));
      expect(container.read(showcaseProvider).expanded, {'payment'});

      await tester.tap(find.text(ShowcaseCopy.layoutOrbit));
      await pumpFor(tester, const Duration(seconds: 2));
      expect(container.read(showcaseProvider).layout, ShowcaseLayout.orbit);

      await tester.tap(find.text(ShowcaseCopy.edgeCircuit));
      await pumpFor(tester, const Duration(seconds: 1));
      expect(container.read(showcaseProvider).edgeStyle, ShowcaseEdgeStyle.circuit);

      await tester.tap(find.byTooltip(ShowcaseCopy.reset));
      await pumpFor(tester, const Duration(seconds: 2));
      final state = container.read(showcaseProvider);
      expect(state.layout, ShowcaseLayout.flow);
      expect(state.expanded, isEmpty);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    testWidgets('phone: plays the whole tour with motion', (tester) async {
      final container = await pumpView(tester, const Size(390, 844));
      await tester.tap(find.byTooltip(ShowcaseCopy.playTour));
      final seen = <TourStep>{};
      for (var i = 0; i < 80 && container.read(showcaseProvider).isTouring; i++) {
        await pumpFor(tester, const Duration(seconds: 1));
        final step = container.read(showcaseProvider).tourStep;
        if (step != null) seen.add(step);
      }
      expect(seen, containsAll(TourStep.values));
      final state = container.read(showcaseProvider);
      expect(state.isTouring, isFalse);
      expect(state.layout, ShowcaseLayout.stack);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    testWidgets('desktop: plays the whole tour with reduced motion', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final container = await pumpView(tester, const Size(1400, 900));
      await tester.tap(find.text(ShowcaseCopy.playTour));
      await pumpFor(tester, const Duration(seconds: 20));
      expect(container.read(showcaseProvider).isTouring, isTrue);
      await pumpFor(tester, const Duration(seconds: 60));
      final state = container.read(showcaseProvider);
      expect(state.isTouring, isFalse);
      expect(state.statusOf('delivered'), StepStatus.done);
      expect(state.visibleIds, contains('gift'));
      expect(state.visibleIds, isNot(contains('quality')));
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  });
}
