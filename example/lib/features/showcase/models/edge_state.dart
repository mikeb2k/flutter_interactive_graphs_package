import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/showcase/models/step_status.dart';

/// How lit up an edge is while the order runs.
enum EdgeState {
  /// Not reached yet.
  idle,

  /// Both steps are done.
  lit,

  /// Parcels flow along the edge.
  flowing;

  /// State of [edge] from the state of its steps. Parcels flow into a running step, loops flow
  /// while retrying or after a failure, and an edge between two finished steps stays lit.
  static EdgeState of(GraphEdge edge, Map<String, StepStatus> statuses) {
    final from = statuses[edge.fromId] ?? StepStatus.waiting;
    final to = statuses[edge.toId] ?? StepStatus.waiting;
    return switch ((from, to)) {
      (StepStatus.retrying, _) when edge.isSelfLoop => EdgeState.flowing,
      _ when edge.isSelfLoop => EdgeState.idle,
      (StepStatus.failed, _) when edge.type == EdgeType.back && to.isRunning => EdgeState.flowing,
      _ when edge.type == EdgeType.back => EdgeState.idle,
      (StepStatus.done, _) when to.isRunning => EdgeState.flowing,
      (StepStatus.done, StepStatus.done) => EdgeState.lit,
      _ => EdgeState.idle,
    };
  }
}
