import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:interactive_graphs/src/edges/edge_path.dart';

/// Anchor positions of every node, by node id and anchor id, relative to the node's top-left
/// corner. Anchor ids are scoped per node.
///
/// Anchors register while they paint; listeners hear about changes after the frame, so the edges
/// follow on the next one.
@internal
class AnchorRegistry extends ChangeNotifier {
  final Map<String, Map<String, Offset>> _anchors = {};
  bool _notifyScheduled = false;
  bool _disposed = false;

  /// Offset of [anchorId] on [nodeId], or `null`.
  Offset? offsetOf(String nodeId, String anchorId) => _anchors[nodeId]?[anchorId];

  /// Node ids that have anchors.
  Iterable<String> get nodeIds => _anchors.keys;

  /// Records an anchor position.
  void register(String nodeId, String anchorId, Offset offset) {
    final anchors = _anchors.putIfAbsent(nodeId, () => {});
    if (anchors[anchorId] == offset) return;
    anchors[anchorId] = offset;
    _scheduleNotify();
  }

  /// Forgets one anchor.
  void unregister(String nodeId, String anchorId) {
    final anchors = _anchors[nodeId];
    if (anchors == null || anchors.remove(anchorId) == null) return;
    if (anchors.isEmpty) _anchors.remove(nodeId);
    _scheduleNotify();
  }

  /// Forgets the anchors of every node not in [nodeIds].
  void retain(Set<String> nodeIds) {
    final before = _anchors.length;
    _anchors.removeWhere((id, _) => !nodeIds.contains(id));
    if (_anchors.length != before) _scheduleNotify();
  }

  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// The paths edges were last drawn along, for tap and hover hit testing.
@internal
class EdgeHitRegistry {
  final Map<String, (EdgePath, Rect)> _paths = {};

  /// Records the path of edge [id].
  void report(String id, EdgePath path) => _paths[id] = (path, path.bounds(strokeWidth: 0, showArrow: false));

  /// Forgets every edge not in [ids].
  void retain(Set<String> ids) => _paths.removeWhere((id, _) => !ids.contains(id));

  /// Id of the edge closest to [point] within [tolerance], or `null`.
  String? hitTest(Offset point, double tolerance) {
    String? closestId;
    var closest = tolerance;
    for (final MapEntry(key: id, value: (path, bounds)) in _paths.entries) {
      // The bounds hold every control point, so the curve lies inside them
      if (!bounds.inflate(closest).contains(point)) continue;
      final distance = path.distanceTo(point);
      if (distance <= closest) {
        closest = distance;
        closestId = id;
      }
    }
    return closestId;
  }
}
