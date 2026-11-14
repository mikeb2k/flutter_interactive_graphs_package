import 'dart:async';
import 'dart:isolate';

import 'package:interactive_graphs/src/layout/graph_layout.dart';
import 'package:interactive_graphs/src/layout/layout_config.dart';
import 'package:interactive_graphs/src/model/graph.dart';
import 'package:meta/meta.dart';

/// One layout pass on an isolate of its own, which [cancel] stops at once.
@internal
class BackgroundLayout {
  Isolate? _isolate;
  bool _cancelled = false;

  /// Lays [graph] out with [config]. Completes with `null` when [cancel] stopped the isolate, and
  /// with the isolate's error when the layout threw.
  Future<Graph?> run(Graph graph, LayoutConfig config) async {
    final port = ReceivePort();
    try {
      final isolate = await Isolate.spawn(
        _LayoutIsolate.run,
        (port.sendPort, graph, config),
        onError: port.sendPort,
        onExit: port.sendPort,
      );
      _isolate = isolate;
      if (_cancelled) isolate.kill(priority: Isolate.immediate);
      // The result, an [error, stack trace] pair, or `null` when the isolate ended without either
      final message = await port.first;
      return switch (message) {
        final Graph laid => laid,
        [final Object error, final Object? stack] => throw RemoteError('$error', '${stack ?? ''}'),
        _ => null,
      };
    } finally {
      port.close();
    }
  }

  /// Stops the layout; [run] then completes with `null`.
  void cancel() {
    _cancelled = true;
    _isolate?.kill(priority: Isolate.immediate);
  }
}

/// Entry point of the isolate; static so it can cross into it.
abstract final class _LayoutIsolate {
  static void run((SendPort, Graph, LayoutConfig) args) {
    final (port, graph, config) = args;
    Isolate.exit(port, GraphLayout.run(graph, config));
  }
}
