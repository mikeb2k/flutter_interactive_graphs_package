import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

void main() {
  Graph pair() => Graph.build(
    (g) => g
      ..nodes(['A', 'B'])
      ..edge('A', 'B'),
  );

  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(800, 600)),
      child: Center(child: SizedBox(width: 800, height: 600, child: child)),
    ),
  );

  Widget box(NodeDetails details) => Container(
    key: ValueKey('node-${details.node.id}'),
    width: 60,
    height: 40,
    color: details.isSelected ? const Color(0xFF2196F3) : const Color(0xFFEEEEEE),
    child: Center(child: Text(details.isSelected ? '${details.node.id}*' : details.node.id)),
  );

  Future<GraphViewerController> pumpViewer(
    WidgetTester tester, {
    Graph? graph,
    GraphViewerConfig config = const GraphViewerConfig(),
    GraphInteractionCallbacks callbacks = const GraphInteractionCallbacks(),
    GraphEdgeBuilder? edgeBuilder,
    GraphNodeBuilder? nodeBuilder,
  }) async {
    final controller = GraphViewerController(graph: graph ?? pair());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        GraphViewer(
          controller: controller,
          config: config,
          callbacks: callbacks,
          edgeBuilder: edgeBuilder,
          nodeBuilder: nodeBuilder ?? (context, details) => box(details),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Offset centerOf(GraphViewerController controller, String id) =>
      controller.graphToViewport(controller.layoutedGraph.nodes[id]!.position);

  testWidgets('measures, lays out and fits the nodes', (tester) async {
    final controller = await pumpViewer(tester);

    expect(find.text('A'), findsOneWidget);
    expect(controller.hasFittedInitially, isTrue);
    expect(controller.layoutedGraph.nodes['A']!.size, const Size(60, 40));
    final a = tester.getCenter(find.byKey(const ValueKey('node-A')));
    final b = tester.getCenter(find.byKey(const ValueKey('node-B')));
    expect(a.dx, lessThan(b.dx));
    expect(a, offsetMoreOrLessEquals(centerOf(controller, 'A'), epsilon: 0.5));
  });

  testWidgets('tapping a node selects it, tapping the canvas clears it', (tester) async {
    GraphNode? tapped;
    var canvasTaps = 0;
    final controller = await pumpViewer(
      tester,
      config: const GraphViewerConfig(selectionMode: SelectionMode.single),
      callbacks: GraphInteractionCallbacks(onNodeTap: (node) => tapped = node, onCanvasTap: () => canvasTaps++),
    );

    await tester.tap(find.text('A'));
    await tester.pump();
    expect(controller.interaction.selectedNodeIds, {'A'});
    expect(tapped?.id, 'A');
    expect(find.text('A*'), findsOneWidget, reason: 'the builder sees isSelected');

    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(controller.interaction.selectedNodeIds, isEmpty);
    expect(canvasTaps, 1);
  });

  testWidgets('dragging the canvas pans, dragging a node moves it when enabled', (tester) async {
    final panned = await pumpViewer(tester);
    final offset = panned.offset;
    await tester.dragFrom(centerOf(panned, 'A'), const Offset(100, 40));
    await tester.pumpAndSettle();
    expect(panned.offset - offset, offsetMoreOrLessEquals(const Offset(100, 40), epsilon: 1));
    expect(panned.manualPositions, isEmpty);

    Offset? travelled;
    final dragged = await pumpViewer(
      tester,
      config: const GraphViewerConfig(nodeDragEnabled: true),
      callbacks: GraphInteractionCallbacks(onNodeDragEnd: (node, offset) => travelled = offset),
    );
    final bBefore = centerOf(dragged, 'B');
    final start = centerOf(dragged, 'A');
    await tester.dragFrom(start, const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(dragged.manualPositions.keys, ['A']);
    expect(travelled!.dy * dragged.scale, closeTo(120, 1));
    expect(centerOf(dragged, 'A'), offsetMoreOrLessEquals(start + const Offset(0, 120), epsilon: 1));
    expect(centerOf(dragged, 'B'), offsetMoreOrLessEquals(bBefore, epsilon: 0.5));
    expect(
      tester.getCenter(find.byKey(const ValueKey('node-A'))),
      offsetMoreOrLessEquals(start + const Offset(0, 120), epsilon: 1),
    );
  });

  testWidgets('scroll pans and ctrl+scroll zooms about the pointer', (tester) async {
    final controller = await pumpViewer(tester);
    final offset = controller.offset;
    final scale = controller.scale;
    const pointer = Offset(300, 250);

    await tester.sendEventToBinding(const PointerScrollEvent(position: pointer, scrollDelta: Offset(0, 50)));
    await tester.pump();
    expect(controller.offset, offsetMoreOrLessEquals(offset - const Offset(0, 50)));

    final under = controller.viewportToGraph(pointer - tester.getTopLeft(find.byType(GraphViewer)));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendEventToBinding(const PointerScrollEvent(position: pointer, scrollDelta: Offset(0, -100)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(controller.scale, greaterThan(scale));
    expect(
      controller.viewportToGraph(pointer - tester.getTopLeft(find.byType(GraphViewer))),
      offsetMoreOrLessEquals(under, epsilon: 0.01),
    );
  });

  testWidgets('zoomIn animates to its target', (tester) async {
    final controller = await pumpViewer(tester);
    final scale = controller.scale;

    controller.zoomIn();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.scale, isNot(scale));
    await tester.pumpAndSettle();
    expect(controller.scale, closeTo(scale * 1.2, 1e-6));
  });

  testWidgets('tapping an edge selects it', (tester) async {
    GraphEdge? tapped;
    final controller = await pumpViewer(
      tester,
      config: const GraphViewerConfig(edgeSelectionMode: SelectionMode.single),
      callbacks: GraphInteractionCallbacks(onEdgeTap: (edge) => tapped = edge),
      edgeBuilder: (context, details) => StyledEdge(details: details, label: details.isSelected ? 'on' : 'off'),
    );
    final middle = (centerOf(controller, 'A') + centerOf(controller, 'B')) / 2;

    expect(find.text('off'), findsOneWidget);
    await tester.tapAt(middle);
    await tester.pump();
    expect(controller.interaction.selectedEdgeIds, {'A->B'});
    expect(tapped?.id, 'A->B');
    expect(find.text('on'), findsOneWidget);

    await tester.tapAt(middle + const Offset(0, 100));
    await tester.pump();
    expect(controller.interaction.selectedEdgeIds, isEmpty);
  });

  testWidgets('the batched edge layer is hit-testable too', (tester) async {
    final controller = await pumpViewer(
      tester,
      config: const GraphViewerConfig(edgeSelectionMode: SelectionMode.multiple),
    );

    await tester.tapAt((centerOf(controller, 'A') + centerOf(controller, 'B')) / 2);
    await tester.pump();
    expect(controller.interaction.selectedEdgeIds, {'A->B'});
  });

  testWidgets('edges attach to anchors', (tester) async {
    final details = <EdgeDetails>[];
    final controller = await pumpViewer(
      tester,
      graph: Graph.build(
        (g) => g
          ..nodes(['A', 'B'])
          ..edge('A', 'B', fromAnchor: 'bottom'),
      ),
      nodeBuilder: (context, node) => const SizedBox(
        width: 80,
        height: 40,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GraphAnchor(id: 'bottom'),
        ),
      ),
      edgeBuilder: (context, edge) {
        details.add(edge);
        return StyledEdge(details: edge);
      },
    );

    final center = tester.getSize(find.byType(GraphViewer)).center(Offset.zero);
    final a = controller.layoutedGraph.nodes['A']!;
    final expected = center + (a.position - controller.graphCenter) + const Offset(0, 20);
    expect(details.last.from, offsetMoreOrLessEquals(expected, epsilon: 0.5));
  });

  testWidgets('hovering a node and an edge updates the interaction', (tester) async {
    final controller = await pumpViewer(
      tester,
      config: const GraphViewerConfig(hoverEnabled: true, edgeHoverEnabled: true),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);

    await mouse.moveTo(centerOf(controller, 'A'));
    await tester.pump();
    expect(controller.interaction.hoveredNodeId, 'A');

    await mouse.moveTo((centerOf(controller, 'A') + centerOf(controller, 'B')) / 2);
    await tester.pump();
    expect(controller.interaction.hoveredNodeId, isNull);
    expect(controller.interaction.hoveredEdgeId, 'A->B');
  });

  testWidgets('a new graph animates the nodes to their new places', (tester) async {
    final controller = await pumpViewer(tester);
    final before = tester.getCenter(find.byKey(const ValueKey('node-A')));

    controller.updateGraph(
      controller.graph.rebuild(
        (g) => g
          ..nodes(['C'])
          ..edge('C', 'A'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final midway = tester.getCenter(find.byKey(const ValueKey('node-A')));
    await tester.pumpAndSettle();
    final after = tester.getCenter(find.byKey(const ValueKey('node-A')));

    expect(after, isNot(offsetMoreOrLessEquals(before)));
    expect(midway, isNot(offsetMoreOrLessEquals(after)));
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('an empty graph shows nothing and throws nothing', (tester) async {
    final controller = await pumpViewer(tester, graph: Graph.empty());

    expect(controller.layoutedGraph.nodes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a large measured graph is laid out on the background isolate', (tester) async {
    final graph = Graph.build((g) {
      g.nodes([for (var i = 0; i < 400; i++) 'n$i']);
      for (var i = 1; i < 400; i++) {
        g.edge('n${i ~/ 2}', 'n$i');
      }
    });
    final controller = GraphViewerController(graph: graph, backgroundLayoutThreshold: 400);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        GraphViewer(
          controller: controller,
          nodeBuilder: (context, details) => const SizedBox(width: 30, height: 20),
        ),
      ),
    );
    for (var i = 0; i < 100 && !controller.hasFittedInitially; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
    expect(controller.hasFittedInitially, isTrue);
    expect(controller.layoutedGraph.nodes['n1']!.position, isNot(Offset.zero));
  });

  Graph twins() => Graph.build(
    (g) => g
      ..nodes(['A', 'B'])
      ..edge('A', 'B', id: 'p')
      ..edge('A', 'B', id: 'q'),
  );

  for (final batched in [true, false]) {
    testWidgets('parallel edges of a shape that does not fan out run straight between the nodes '
        '(${batched ? 'batched' : 'edgeBuilder'})', (tester) async {
      GraphEdge? tapped;
      final controller = GraphViewerController(graph: twins());
      addTearDown(controller.dispose);
      const style = EdgeStyle(shape: EdgeShape.orthogonal, showArrow: false);
      await tester.pumpWidget(
        host(
          GraphViewer(
            controller: controller,
            config: const GraphViewerConfig(edgeHitTolerance: 2),
            callbacks: GraphInteractionCallbacks(onEdgeTap: (edge) => tapped = edge),
            edgeStyle: batched ? (details) => style : null,
            edgeBuilder: batched ? null : (context, details) => EdgeLine(details: details, style: style),
            nodeBuilder: (context, details) => box(details),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final middle = (centerOf(controller, 'A') + centerOf(controller, 'B')) / 2;
      await tester.tapAt(middle);
      expect(tapped, isNotNull);
    });
  }

  testWidgets('moving one node rebuilds only that node', (tester) async {
    final builds = <String, int>{};
    final controller = await pumpViewer(
      tester,
      nodeBuilder: (context, details) {
        builds.update(details.node.id, (n) => n + 1, ifAbsent: () => 1);
        return box(details);
      },
    );
    final before = Map.of(builds);

    controller.moveNodeBy('A', const Offset(0, 30));
    await tester.pumpAndSettle();

    expect(builds['A'], greaterThan(before['A']!));
    expect(builds['B'], before['B']);
  });

  testWidgets('moving one node leaves the widgets of the other nodes alone', (tester) async {
    final controller = await pumpViewer(tester);
    Widget slotOf(String id) => tester.widget(find.byKey(ValueKey(id)));
    final a = slotOf('A');
    final b = slotOf('B');

    controller.moveNodeBy('A', const Offset(0, 30));
    await tester.pumpAndSettle();

    expect(slotOf('A'), isNot(same(a)));
    expect(slotOf('B'), same(b));
  });

  testWidgets('rebuildNodesOnLayout: false builds a node once and again only when its state changes', (tester) async {
    final builds = <String, int>{};
    final controller = await pumpViewer(
      tester,
      config: const GraphViewerConfig(rebuildNodesOnLayout: false, selectionMode: SelectionMode.single),
      nodeBuilder: (context, details) {
        builds.update(details.node.id, (n) => n + 1, ifAbsent: () => 1);
        return box(details);
      },
    );
    expect(builds, {'A': 1, 'B': 1});

    controller.updateGraph(
      controller.graph.rebuild(
        (g) => g
          ..node('C')
          ..edge('B', 'C'),
      ),
    );
    await tester.pumpAndSettle();
    expect(builds, {'A': 1, 'B': 1, 'C': 1});

    controller.interaction.select('A');
    await tester.pump();
    expect(builds, {'A': 2, 'B': 1, 'C': 1});
  });

  testWidgets('panning and zooming repaint nothing', (tester) async {
    var arrows = 0;
    void countingArrow(Canvas canvas, Offset tip, Offset direction, Color color, double size) => arrows++;
    final controller = GraphViewerController(graph: pair());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        GraphViewer(
          controller: controller,
          nodeBuilder: (context, details) => box(details),
          edgeStyle: (details) => EdgeStyle(arrowPainter: countingArrow),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(arrows, greaterThan(0));
    arrows = 0;

    controller.updateTransform(scale: 1.5, offset: const Offset(40, -20));
    await tester.pump();

    expect(arrows, 0);
    expect(controller.scale, 1.5);
  });

  testWidgets('hovering a node repaints no edge, selecting an edge repaints them', (tester) async {
    var arrows = 0;
    void countingArrow(Canvas canvas, Offset tip, Offset direction, Color color, double size) => arrows++;
    final controller = GraphViewerController(graph: pair());
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        GraphViewer(
          controller: controller,
          config: const GraphViewerConfig(hoverEnabled: true, edgeSelectionMode: SelectionMode.single),
          nodeBuilder: (context, details) => box(details),
          edgeStyle: (details) => EdgeStyle(arrowPainter: countingArrow),
        ),
      ),
    );
    await tester.pumpAndSettle();
    arrows = 0;

    controller.interaction.hoveredNodeId = 'A';
    await tester.pump();
    expect(arrows, 0);

    controller.interaction.selectEdge('A->B');
    await tester.pump();
    expect(arrows, 1);
  });

  testWidgets('hovering a node rebuilds no edge widget, dragging one rebuilds only its edges', (tester) async {
    final builds = <String, int>{};
    final controller = await pumpViewer(
      tester,
      graph: Graph.build(
        (g) => g
          ..nodes(['A', 'B', 'C', 'D'])
          ..edge('A', 'B', id: 'ab')
          ..edge('C', 'D', id: 'cd'),
      ),
      config: const GraphViewerConfig(hoverEnabled: true, nodeDragEnabled: true),
      edgeBuilder: (context, details) {
        builds.update(details.edge.id, (n) => n + 1, ifAbsent: () => 1);
        return StyledEdge(details: details);
      },
    );
    final settled = Map.of(builds);

    controller.interaction.hoveredNodeId = 'A';
    await tester.pump();
    expect(builds, settled);

    controller.interaction
      ..startDrag('A')
      ..dragBy(const Offset(0, 20));
    await tester.pump();
    expect(builds['ab'], greaterThan(settled['ab']!));
    expect(builds['cd'], settled['cd']);
  });

  test('config copyWith reaches every field', () {
    const config = GraphViewerConfig();
    expect(config.animateLayout, isTrue);
    expect(config.enterDuration, Duration.zero);
    final changed = config.copyWith(animateLayout: false, enterDuration: const Duration(seconds: 1));
    expect(changed.animateLayout, isFalse);
    expect(changed.enterDuration, const Duration(seconds: 1));
    expect(changed, isNot(config));
  });

  test('the viewer config compares by value and copyWith reaches every field', () {
    const config = GraphViewerConfig();
    bool always(PointerScrollEvent event) => true;
    final changed = [
      config.copyWith(showDebugBounds: true),
      config.copyWith(fitToContent: false),
      config.copyWith(contentPadding: 0.5),
      config.copyWith(minScale: 0.5),
      config.copyWith(maxScale: 3),
      config.copyWith(zoomStep: 2),
      config.copyWith(scrollPanSpeed: 2),
      config.copyWith(scrollZoomSpeed: 0.01),
      config.copyWith(scrollZoomCondition: always),
      config.copyWith(selectionMode: SelectionMode.single),
      config.copyWith(nodeDragEnabled: true),
      config.copyWith(hoverEnabled: true),
      config.copyWith(edgeSelectionMode: SelectionMode.multiple),
      config.copyWith(edgeHoverEnabled: true),
      config.copyWith(edgeHitTolerance: 20),
      config.copyWith(relayoutPolicy: RelayoutPolicy.relayoutAll),
      config.copyWith(transformSpring: const SpringDescription(mass: 2, stiffness: 50, damping: 5)),
      config.copyWith(layoutSpring: const SpringDescription(mass: 2, stiffness: 50, damping: 5)),
      config.copyWith(animateLayout: false),
      config.copyWith(animateInitialPlacement: true),
      config.copyWith(enterDuration: const Duration(seconds: 1)),
      config.copyWith(rebuildNodesOnLayout: false),
    ];

    expect(config.copyWith(), config);
    expect(config.copyWith().hashCode, config.hashCode);
    for (final other in changed) {
      expect(other, isNot(config));
    }
    expect(changed.toSet(), hasLength(changed.length));
  });

  test('interaction callbacks compare by their handlers', () {
    void onTap(GraphNode node) {}
    void onCanvasTap() {}
    final callbacks = GraphInteractionCallbacks(onNodeTap: onTap, onCanvasTap: onCanvasTap);

    expect(callbacks, GraphInteractionCallbacks(onNodeTap: onTap, onCanvasTap: onCanvasTap));
    expect(callbacks.hashCode, GraphInteractionCallbacks(onNodeTap: onTap, onCanvasTap: onCanvasTap).hashCode);
    expect(callbacks, isNot(GraphInteractionCallbacks(onNodeTap: onTap)));
    expect(callbacks.handlesNodeTap, isTrue);
    expect(const GraphInteractionCallbacks().handlesNodeTap, isFalse);
  });

  testWidgets('animateLayout: false places nodes at once', (tester) async {
    final controller = await pumpViewer(tester, config: const GraphViewerConfig(animateLayout: false));
    final before = tester.getCenter(find.byKey(const ValueKey('node-B')));

    controller.layoutConfig = const LayoutConfig.hierarchical(direction: LayoutDirection.vertical);
    await tester.pump();
    await tester.pump();

    final after = tester.getCenter(find.byKey(const ValueKey('node-B')));
    expect(after, isNot(before));
    expect(after, offsetMoreOrLessEquals(centerOf(controller, 'B'), epsilon: 0.5));
  });
}
