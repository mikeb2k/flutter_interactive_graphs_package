import 'package:material_ui/material_ui.dart';

/// Connect mode of the playground: after a first node tap, the next tapped node gets an edge from
/// [sourceNodeId].
@immutable
class PlaygroundConnection {
  /// Creates a connection state; inactive without [sourceNodeId].
  const PlaygroundConnection({this.sourceNodeId});

  /// Not connecting.
  static const PlaygroundConnection none = PlaygroundConnection();

  /// Node the new edge starts at, `null` when not connecting.
  final String? sourceNodeId;

  /// Whether a source node is picked and the next tap connects.
  bool get isActive => sourceNodeId != null;

  /// Starts connecting from [nodeId].
  PlaygroundConnection start(String nodeId) => PlaygroundConnection(sourceNodeId: nodeId);

  /// Leaves connect mode.
  PlaygroundConnection reset() => none;

  @override
  bool operator ==(Object other) => other is PlaygroundConnection && other.sourceNodeId == sourceNodeId;

  @override
  int get hashCode => sourceNodeId.hashCode;
}
