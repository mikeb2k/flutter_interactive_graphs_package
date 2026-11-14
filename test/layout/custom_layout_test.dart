import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

void main() {
  Graph triangle() => Graph.build(
    (g) => g
      ..nodes(['A', 'B', 'C'])
      ..edges([('A', 'B'), ('B', 'C'), ('C', 'A')]),
  );

  test('layout configs compare by value', () {
    Graph keep(Graph graph, LayoutConfig config) => graph;
    Graph other(Graph graph, LayoutConfig config) => graph;
    const canvas = Size(400, 300);

    const hierarchical = LayoutConfig.hierarchical();
    expect(hierarchical, const LayoutConfig.hierarchical());
    expect(hierarchical.hashCode, const LayoutConfig.hierarchical().hashCode);
    expect(hierarchical, isNot(const LayoutConfig.hierarchical(direction: LayoutDirection.vertical)));
    expect(hierarchical.withCanvas(canvas), isNot(hierarchical));

    const forceDirected = LayoutConfig.forceDirected();
    expect(forceDirected, const LayoutConfig.forceDirected());
    expect(forceDirected.hashCode, const LayoutConfig.forceDirected().hashCode);
    expect(forceDirected, isNot(const LayoutConfig.forceDirected(iterations: 10)));
    expect(forceDirected, isNot(hierarchical));

    final custom = LayoutConfig.custom(keep);
    expect(custom, LayoutConfig.custom(keep));
    expect(custom.hashCode, LayoutConfig.custom(keep).hashCode);
    expect(custom, isNot(LayoutConfig.custom(other)));
    expect(custom.withCanvas(canvas), isNot(custom));
  });

  test('the provider receives the graph and the config with the canvas', () {
    Graph? received;
    LayoutConfig? receivedConfig;
    final config = LayoutConfig.custom((graph, config) {
      received = graph;
      receivedConfig = config;
      return graph;
    });

    GraphLayout.run(triangle(), config.withCanvas(const Size(400, 300)));

    expect(received, triangle());
    expect(receivedConfig!.canvasSize, const Size(400, 300));
  });

  test('a circular layout places every node on the circle and keeps the edges', () {
    Graph circular(Graph graph, LayoutConfig config) {
      final nodes = graph.nodes.values.toList();
      final radius = math.min(config.canvasSize.width, config.canvasSize.height) * 0.4;
      final center = config.canvasSize.center(Offset.zero);
      return Graph.withClassifiedEdges([
        for (var i = 0; i < nodes.length; i++)
          nodes[i].copyWith(
            position: center + Offset.fromDirection(i / nodes.length * 2 * math.pi, radius),
          ),
      ], graph.edges);
    }

    final result = GraphLayout.run(
      triangle(),
      const CustomLayoutConfig(provider: _CircularProvider.layout, canvasSize: Size(500, 500)),
    );
    final viaFunction = GraphLayout.run(triangle(), LayoutConfig.custom(circular, canvasSize: const Size(500, 500)));

    expect(result, viaFunction);
    for (final node in result.nodes.values) {
      expect((node.position - const Offset(250, 250)).distance, closeTo(200, 0.001));
    }
    expect(result.edges, hasLength(3));
    expect(result.edges.every((e) => e.type != null), isTrue);
  });

  test('an empty graph goes through untouched', () {
    final result = GraphLayout.run(Graph.empty(), LayoutConfig.custom((graph, _) => graph));

    expect(result.nodes, isEmpty);
  });

  test('configs compare by value so the viewer can tell when to lay out again', () {
    expect(const LayoutConfig.hierarchical(), const HierarchicalLayoutConfig());
    expect(
      const LayoutConfig.hierarchical(nodeSpacing: 10),
      isNot(const LayoutConfig.hierarchical(nodeSpacing: 20)),
    );
    expect(const LayoutConfig.forceDirected().withCanvas(const Size(1, 2)).canvasSize, const Size(1, 2));
    expect(
      const LayoutConfig.forceDirected(iterations: 5).withCanvas(const Size(1, 2)),
      const ForceDirectedLayoutConfig(iterations: 5, canvasSize: Size(1, 2)),
    );
  });
}

abstract final class _CircularProvider {
  static Graph layout(Graph graph, LayoutConfig config) {
    final nodes = graph.nodes.values.toList();
    final radius = math.min(config.canvasSize.width, config.canvasSize.height) * 0.4;
    final center = config.canvasSize.center(Offset.zero);
    return Graph.withClassifiedEdges([
      for (var i = 0; i < nodes.length; i++)
        nodes[i].copyWith(position: center + Offset.fromDirection(i / nodes.length * 2 * math.pi, radius)),
    ], graph.edges);
  }
}
