import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

void main() {
  Graph chain() => Graph.build(
    (g) => g
      ..node('A', size: const Size(40, 40))
      ..node('B', size: const Size(40, 40))
      ..node('C', size: const Size(40, 40))
      ..edges([('A', 'B'), ('B', 'C')]),
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<GraphViewerController> laidOut({Graph? graph, LayoutConfig? config}) async {
    final controller = GraphViewerController(
      graph: graph ?? chain(),
      layoutConfig: config ?? const LayoutConfig.hierarchical(),
    );
    controller.reportCanvasSize(const Size(800, 600));
    await settle();
    return controller;
  }

  test('lays out once the canvas is known and classifies the edges', () async {
    final controller = GraphViewerController(graph: chain());
    expect(controller.layoutedGraph, same(controller.graph));

    controller.reportCanvasSize(const Size(800, 600));
    expect(controller.isLayoutPending, isTrue);
    await settle();

    final laid = controller.layoutedGraph;
    expect(laid.nodes['A']!.position.dx, lessThan(laid.nodes['B']!.position.dx));
    expect(laid.edges.every((e) => e.type == EdgeType.forward), isTrue);
    expect(controller.hasFittedInitially, isTrue);
    expect(controller.isLayoutPending, isFalse);
  });

  test('the initial fit waits for node sizes', () async {
    final controller = GraphViewerController(graph: Graph.build((g) => g.nodes(['A', 'B'])));
    controller.reportCanvasSize(const Size(800, 600));
    await settle();
    expect(controller.hasFittedInitially, isFalse);

    controller.reportMeasuredSizes(const {'A': Size(30, 20), 'B': Size(30, 20)});
    await settle();
    expect(controller.hasFittedInitially, isTrue);
    expect(controller.layoutedGraph.nodes['A']!.size, const Size(30, 20));
  });

  test('fitting scales the node bounds to the content padding', () async {
    final controller = await laidOut();
    final bounds = GraphBounds.ofNodes(controller.layoutedGraph.nodes.values);

    final topLeft = controller.graphToViewport(bounds.topLeft);
    final bottomRight = controller.graphToViewport(bounds.bottomRight);
    final fitted = Rect.fromPoints(topLeft, bottomRight);
    expect(fitted.width, lessThanOrEqualTo(800 * 0.8 + 0.5));
    expect(fitted.height, lessThanOrEqualTo(600 * 0.8 + 0.5));
    expect(fitted.width > 800 * 0.8 - 0.5 || fitted.height > 600 * 0.8 - 0.5, isTrue);
    expect(fitted.center.dx, closeTo(400, 1));
  });

  test('an equal graph is a no-op, a new one is laid out', () async {
    final controller = await laidOut();
    var notified = 0;
    controller.addListener(() => notified++);

    controller.updateGraph(chain());
    expect(notified, 0);

    controller.updateGraph(chain().rebuild((g) => g.node('D', size: const Size(40, 40))));
    await settle();
    expect(controller.layoutedGraph.nodes, contains('D'));
    expect(notified, greaterThan(0));
  });

  test('viewport and graph coordinates convert both ways', () async {
    final controller = await laidOut()
      ..updateTransform(scale: 2, offset: const Offset(30, -20));
    const point = Offset(123, 45);

    expect(controller.viewportToGraph(controller.graphToViewport(point)), offsetMoreOrLessEquals(point));
    expect(controller.graphToViewport(controller.graphCenter), const Offset(430, 280));
  });

  test('a gesture zooms about its focal point', () async {
    final controller = await laidOut();
    const focal = Offset(200, 150);
    final before = controller.viewportToGraph(focal);

    controller.applyGesture(focalPoint: focal, factor: 1.5);
    expect(controller.viewportToGraph(focal), offsetMoreOrLessEquals(before));

    controller.applyGesture(factor: 1000);
    expect(controller.scale, controller.config.maxScale);
  });

  test('moveNode records a manual position and keeps the other nodes on screen', () async {
    final controller = await laidOut();
    final bOnScreen = controller.graphToViewport(controller.layoutedGraph.nodes['B']!.position);

    controller.moveNodeBy('A', const Offset(0, 200));

    expect(controller.manualPositions.keys, ['A']);
    expect(
      controller.graphToViewport(controller.layoutedGraph.nodes['B']!.position),
      offsetMoreOrLessEquals(bOnScreen),
    );
    expect(controller.isManualLayout(controller.layoutedGraph), isTrue);
  });

  test('manual positions survive a relayout under keepManual only', () async {
    final controller = await laidOut();
    final target = controller.layoutedGraph.nodes['A']!.position + const Offset(0, 300);
    controller
      ..moveNode('A', target)
      ..relayout();
    await settle();
    expect(controller.layoutedGraph.nodes['A']!.position, target);

    controller
      ..attachConfig(const GraphViewerConfig(relayoutPolicy: RelayoutPolicy.relayoutAll))
      ..relayout();
    await settle();
    expect(controller.layoutedGraph.nodes['A']!.position, isNot(target));

    controller.clearManualPositions();
    expect(controller.manualPositions, isEmpty);
  });

  test('manual positions of removed nodes are dropped', () async {
    final controller = await laidOut();
    controller
      ..moveNodeBy('C', const Offset(10, 10))
      ..updateGraph(controller.graph.withoutNode('C'));
    await settle();

    expect(controller.manualPositions, isEmpty);
  });

  test('zoomIn asks for an animation, a direct update cancels it', () async {
    final controller = await laidOut();
    final scale = controller.scale;

    controller.zoomIn();
    final request = controller.animationListenable.value;
    expect(request!.target.scale, closeTo(scale * 1.2, 1e-9));
    expect(controller.scale, scale, reason: 'the viewer runs the animation');

    controller.updateTransform(scale: 1);
    expect(controller.animationListenable.value, isNull);
    controller.applyAnimationFrame(request, const GraphTransform(3, Offset.zero));
    expect(controller.scale, 1, reason: 'a superseded request writes nothing');
  });

  test('removing nodes and edges prunes the interaction state', () async {
    final controller = await laidOut();
    controller.interaction
      ..select('C')
      ..hoveredNodeId = 'C';

    controller.updateGraph(controller.graph.withoutNode('C'));
    await settle();

    expect(controller.interaction.selectedNodeIds, isEmpty);
    expect(controller.interaction.hoveredNodeId, isNull);
  });

  test('a stale layout result is discarded', () async {
    final controller = GraphViewerController(graph: chain());
    controller
      ..reportCanvasSize(const Size(800, 600))
      ..layoutConfig = const LayoutConfig.hierarchical(direction: LayoutDirection.vertical);
    await settle();

    final laid = controller.layoutedGraph;
    expect(laid.nodes['A']!.position.dy, lessThan(laid.nodes['B']!.position.dy));
  });

  group('interaction', () {
    test('single, multiple and canvas taps', () {
      final interaction = GraphInteraction()
        ..tapNode('A', SelectionMode.single)
        ..tapNode('B', SelectionMode.single);
      expect(interaction.selectedNodeIds, {'B'});

      interaction
        ..tapNode('A', SelectionMode.multiple)
        ..tapNode('B', SelectionMode.multiple);
      expect(interaction.selectedNodeIds, {'A'});

      interaction.tapEdge('e', SelectionMode.single);
      expect(interaction.selectedEdgeIds, {'e'});
      expect(interaction.selectedNodeIds, isEmpty, reason: 'nodes and edges share one selection');

      interaction.tapCanvas(SelectionMode.none, SelectionMode.single);
      expect(interaction.selectedEdgeIds, isEmpty);
    });

    test('notifies on flag changes, not on drag movement', () {
      final interaction = GraphInteraction();
      var notified = 0;
      interaction.addListener(() => notified++);

      interaction
        ..startDrag('A')
        ..dragBy(const Offset(5, 5))
        ..dragBy(const Offset(5, 5));
      expect(notified, 1);
      expect(interaction.dragOffsetOf('A'), const Offset(10, 10));
      expect(interaction.dragOffsetOf('B'), Offset.zero);

      interaction.endDrag();
      expect(notified, 2);
      expect(interaction.dragOffset.value, Offset.zero);

      interaction.select('A');
      interaction.select('A');
      expect(notified, 3);
    });
  });
}
