import 'package:interactive_graphs/src/layout/graph_layout.dart';
import 'package:interactive_graphs/src/layout/layout_config.dart';
import 'package:interactive_graphs/src/model/graph.dart';
import 'package:meta/meta.dart';

/// The web has no isolates: the layout runs where it is called and cannot be stopped. The
/// controller lays out on the UI thread there and does not get here.
@internal
class BackgroundLayout {
  /// Lays [graph] out with [config].
  Future<Graph?> run(Graph graph, LayoutConfig config) async => GraphLayout.run(graph, config);

  /// Does nothing.
  void cancel() {}
}
