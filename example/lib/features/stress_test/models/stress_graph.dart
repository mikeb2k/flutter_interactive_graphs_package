import 'dart:math' as math;

import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_node_data.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_node_size.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_test_copy.dart';
import 'package:interactive_graphs_example/models/node_data.dart';
import 'package:material_ui/material_ui.dart';

/// A random connected graph and the data of its nodes, generated from a node count and a seed.
///
/// Generation is deterministic, so two instances with the same [nodeCount] and [seed] are equal.
@immutable
class StressGraph {
  const StressGraph._({required this.nodeCount, required this.seed, required this.graph, required this.nodeData});

  /// Generates [nodeCount] nodes with random sizes and colors, a random spanning path through all
  /// of them for connectivity and about 40 % extra random edges.
  factory StressGraph.generate({required int nodeCount, required int seed}) {
    final random = math.Random(seed);
    StressNodeData randomNode(int index) {
      final size = StressNodeSize.values[random.nextInt(StressNodeSize.values.length)];
      final colorType = NodeColorType.values[random.nextInt(NodeColorType.values.length)];
      return StressNodeData(label: StressTestCopy.nodeLabel(index, size), colorType: colorType, size: size);
    }

    final ids = [for (var i = 1; i <= nodeCount; i++) '$i'];
    final nodeData = <String, StressNodeData>{
      for (var i = 1; i <= nodeCount; i++) '$i': randomNode(i),
    };

    final shuffled = List.of(ids)..shuffle(random);
    final edges = <(String, String)>{for (var i = 1; i < shuffled.length; i++) (shuffled[i - 1], shuffled[i])};
    final extraCount = (nodeCount * 0.4).toInt();
    var attempts = 0;
    while (edges.length < nodeCount - 1 + extraCount && attempts < extraCount * 10) {
      final from = ids[random.nextInt(ids.length)];
      final to = ids[random.nextInt(ids.length)];
      if (from != to) edges.add((from, to));
      attempts++;
    }

    final graph = Graph.build((builder) {
      builder.nodes(ids);
      for (final (from, to) in edges) {
        builder.edge(from, to);
      }
    });
    return StressGraph._(nodeCount: nodeCount, seed: seed, graph: graph, nodeData: Map.unmodifiable(nodeData));
  }

  /// Number of generated nodes.
  final int nodeCount;

  /// Seed of the random generator.
  final int seed;

  /// The graph, not laid out yet.
  final Graph graph;

  /// Data of every node, by node id.
  final Map<String, StressNodeData> nodeData;

  @override
  bool operator ==(Object other) => other is StressGraph && other.nodeCount == nodeCount && other.seed == seed;

  @override
  int get hashCode => Object.hash(nodeCount, seed);
}
