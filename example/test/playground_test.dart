import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_copy.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_ports.dart';
import 'package:interactive_graphs_example/features/playground/models/port_side.dart';
import 'package:interactive_graphs_example/features/playground/providers/playground_provider.dart';
import 'package:interactive_graphs_example/features/playground/views/playground_view.dart';
import 'package:interactive_graphs_example/models/layout_algorithm.dart';
import 'package:interactive_graphs_example/models/node_data.dart';
import 'package:interactive_graphs_example/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [playgroundProvider.overrideWith(() => PlaygroundNotifier(random: Random(7)))],
    );
    addTearDown(container.dispose);
    container.listen(playgroundProvider, (_, _) {});
    return container;
  }

  group('PlaygroundNotifier', () {
    test('starts with the four-node demo graph and ports on every edge end', () {
      final state = createContainer().read(playgroundProvider);
      expect(state.graph.nodes.keys, ['1', '2', '3', '4']);
      expect(state.graph.edges.map((e) => e.id), ['e1', 'e2', 'e3', 'e4']);
      expect(state.graph.edges.every((e) => e.fromAnchor != null && e.toAnchor != null), isTrue);
      expect(state.graph.edge('e1')!.fromAnchor, 'out-0');
      expect(state.graph.edge('e2')!.fromAnchor, 'out-1');
      expect(state.nextNodeId, 5);
      expect(state.layoutAlgorithm, LayoutAlgorithm.hierarchical);
    });

    test('ports sit on the flow sides', () {
      final graph = createContainer().read(playgroundProvider).graph;
      final horizontal = graph.portsOf('1', vertical: false);
      expect(horizontal[PortSide.right], ['out-0', 'out-1']);
      final vertical = graph.portsOf('4', vertical: true);
      expect(vertical[PortSide.top], ['in-0', 'in-1']);
    });

    test('toggling ports strips and restores the anchors', () {
      final container = createContainer();
      final notifier = container.read(playgroundProvider.notifier)..togglePorts();
      var graph = container.read(playgroundProvider).graph;
      expect(graph.edges.every((e) => e.fromAnchor == null && e.toAnchor == null), isTrue);
      notifier.togglePorts();
      graph = container.read(playgroundProvider).graph;
      expect(graph.edges.every((e) => e.fromAnchor != null), isTrue);
    });

    test('the node form adds a node, rejects a taken label and resets its label', () {
      final container = createContainer();
      final notifier = container.read(playgroundProvider.notifier)
        ..toggleNodeForm()
        ..setNewNodeLabel('Deploy')
        ..setNewNodeColor(NodeColorType.orange);
      expect(notifier.createNodeFromForm(), isTrue);
      var state = container.read(playgroundProvider);
      expect(state.showNodeForm, isTrue);
      expect(state.nodeData['5'], const NodeData(label: 'Deploy', colorType: NodeColorType.orange));
      expect(state.newNodeLabel, isEmpty);

      notifier.setNewNodeLabel('Start');
      expect(notifier.createNodeFromForm(), isFalse);
      expect(container.read(playgroundProvider).graph.nodes, hasLength(5));

      notifier.setNewNodeLabel('');
      expect(notifier.createNodeFromForm(), isTrue);
      state = container.read(playgroundProvider);
      expect(state.nodeData['6']!.label, 'Node 6');
    });

    test('opening one form closes the other', () {
      final container = createContainer();
      container.read(playgroundProvider.notifier)
        ..toggleNodeForm()
        ..toggleEdgeForm();
      final state = container.read(playgroundProvider);
      expect(state.showEdgeForm, isTrue);
      expect(state.showNodeForm, isFalse);
    });

    test('the edge form connects labelled nodes and stores the edge label', () {
      final container = createContainer();
      final notifier = container.read(playgroundProvider.notifier)
        ..setFromNodeLabel('End')
        ..setToNodeLabel('Start')
        ..setNewEdgeLabel('retry')
        ..setNewEdgeLabelPosition(0.2);
      expect(notifier.createEdgeFromForm(), isTrue);
      final state = container.read(playgroundProvider);
      final edge = state.graph.edge('e5')!;
      expect((edge.fromId, edge.toId), ('4', '1'));
      expect(edge.fromAnchor, startsWith('back-out'));
      expect(state.edgeData['e5']!.label, 'retry');
      expect(state.edgeData['e5']!.labelOffset, 0.2);
      expect(state.fromNodeLabel, isEmpty);
      expect(state.newEdgeLabelPosition, 0.5);

      notifier
        ..setFromNodeLabel('Nope')
        ..setToNodeLabel('Start');
      expect(notifier.createEdgeFromForm(), isFalse);
    });

    test('tapping two nodes connects them and leaves connect mode', () {
      final container = createContainer();
      final notifier = container.read(playgroundProvider.notifier)..tapNode('2');
      expect(container.read(playgroundProvider).connection.sourceNodeId, '2');
      notifier.tapNode('3');
      final state = container.read(playgroundProvider);
      expect(state.connection.isActive, isFalse);
      expect(state.graph.edgesBetween('2', '3'), hasLength(1));

      notifier
        ..tapNode('1')
        ..cancelConnection();
      expect(container.read(playgroundProvider).connection.isActive, isFalse);
    });

    test('removing a node drops its edges and data', () {
      final container = createContainer();
      container.read(playgroundProvider.notifier).removeNode('1');
      final state = container.read(playgroundProvider);
      expect(state.graph.nodes.keys, ['2', '3', '4']);
      expect(state.graph.edges, hasLength(2));
      expect(state.nodeData.containsKey('1'), isFalse);
    });

    test('clearing empties the graph and stops generating', () {
      final container = createContainer();
      container.read(playgroundProvider.notifier)
        ..toggleAutoGenerating()
        ..clearGraph();
      final state = container.read(playgroundProvider);
      expect(state.graph.nodes, isEmpty);
      expect(state.isAutoGenerating, isFalse);
    });

    test('auto generation alternates nodes and edges', () {
      final container = createContainer();
      final notifier = container.read(playgroundProvider.notifier)..autoGenerateStep(addNode: true);
      expect(container.read(playgroundProvider).graph.nodes, hasLength(5));
      expect(container.read(playgroundProvider).nodeData['5']!.label, 'Node 5');
      for (var i = 0; i < 10; i++) {
        notifier.autoGenerateStep(addNode: false);
      }
      final state = container.read(playgroundProvider);
      expect(state.graph.nodes, hasLength(5));
      expect(state.graph.edges.length, greaterThan(4));
    });

    test('the layout config follows the algorithm and direction', () {
      final container = createContainer();
      final notifier = container.read(playgroundProvider.notifier);
      expect(
        container.read(playgroundProvider).layoutConfig(LayoutDirection.vertical),
        const LayoutConfig.hierarchical(direction: LayoutDirection.vertical),
      );
      notifier.setLayoutDirection(LayoutDirection.horizontal);
      expect(container.read(playgroundProvider).isVertical(LayoutDirection.vertical), isFalse);
      notifier.setLayoutAlgorithm(LayoutAlgorithm.forceDirected);
      expect(
        container.read(playgroundProvider).layoutConfig(LayoutDirection.vertical),
        isA<ForceDirectedLayoutConfig>(),
      );
    });
  });

  group('PlaygroundView', () {
    Future<void> pumpView(WidgetTester tester, Size size) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const PlaygroundView(),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    for (final (name, size) in [('phone', const Size(390, 844)), ('desktop', const Size(1400, 900))]) {
      testWidgets('adds a node through the form on $name', (tester) async {
        await pumpView(tester, size);
        expect(find.byType(GraphViewer), findsOneWidget);
        expect(find.text('Start'), findsOneWidget);
        expect(find.text(PlaygroundCopy.graphSize(4, 4)), findsOneWidget);

        await tester.tap(find.byTooltip(PlaygroundCopy.addNode));
        await settle(tester);
        await tester.enterText(find.byType(TextField), 'Deploy');
        await tester.tap(find.byTooltip(PlaygroundCopy.createNode));
        await settle(tester);

        expect(find.text('Deploy'), findsOneWidget);
        expect(find.text(PlaygroundCopy.graphSize(5, 4)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('connects two tapped nodes and generates on $name', (tester) async {
        await pumpView(tester, size);
        await tester.tap(find.text('Start'));
        await settle(tester);
        expect(find.text(PlaygroundCopy.connectFrom('Start')), findsOneWidget);
        await tester.tap(find.text('End'));
        await settle(tester);
        expect(find.text(PlaygroundCopy.graphSize(4, 5)), findsOneWidget);

        await tester.tap(find.byTooltip(PlaygroundCopy.generateNodes));
        await settle(tester);
        await tester.tap(find.byTooltip(PlaygroundCopy.stopGenerating));
        await settle(tester);
        expect(find.text(PlaygroundCopy.graphSize(4, 5)), findsNothing);

        await tester.tap(find.text(PlaygroundCopy.layoutAlgorithm(LayoutAlgorithm.forceDirected)));
        await settle(tester);
        await tester.longPress(find.text('Process'));
        await settle(tester);
        expect(find.text('Process'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
