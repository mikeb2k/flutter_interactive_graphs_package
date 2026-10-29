import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

/// Moves every node from its previous layout position to the new one with one shared 0→1 spring.
///
/// Positions are relative to the graph center. A retarget mid-flight starts from where the nodes
/// are, carrying over their speed, never from the previous layout.
@internal
class LayoutTransition extends ChangeNotifier {
  /// Creates a transition ticking on [vsync].
  LayoutTransition(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  Map<String, Offset> _start = const {};
  Map<String, Offset> _end = const {};
  double _progress = 1;
  SpringSimulation? _simulation;

  // Largest jump a node makes on the frame the transition ends
  double get _finalStep => 0.25;

  // Progress left below which a retarget starts from rest
  double get _minRemaining => 0.05;

  // Cap on the progress speed carried into a retarget, per second
  double get _maxCarriedVelocity => 10.0;

  /// Whether nodes are moving.
  bool get isAnimating => _ticker.isActive;

  /// Position of node [id] at the current point of the transition. Nodes the transition doesn't
  /// know (yet) are placed at their [targets] entry.
  Offset positionOf(String id, Map<String, Offset> targets) {
    final target = targets[id] ?? Offset.zero;
    final from = _start[id];
    final to = _end[id];
    if (from == null || to == null) return target;
    if (from == to || _progress == 1) return to;
    return Offset.lerp(from, to, _progress)!;
  }

  /// Moves every node to [targets] along [spring], or jumps when [spring] is `null`.
  void animateTo(Map<String, Offset> targets, {required SpringDescription? spring}) {
    if (spring == null || _end.isEmpty) {
      _ticker.stop();
      _simulation = null;
      _start = targets;
      _end = targets;
      _progress = 1;
      notifyListeners();
      return;
    }

    final remaining = 1 - _progress;
    var carried = 0.0;
    final running = _simulation;
    if (_ticker.isActive && running != null && remaining > _minRemaining) {
      final velocity = running.dx(_elapsedSeconds);
      carried = (velocity / remaining).clamp(-_maxCarriedVelocity, _maxCarriedVelocity);
    }

    _start = {for (final id in targets.keys) id: positionOf(id, targets)};
    _end = targets;
    _progress = 0;

    final maxTravel = _end.keys.fold(0.0, (max, id) => math.max(max, (_end[id]! - _start[id]!).distance));
    if (maxTravel == 0) {
      _ticker.stop();
      _progress = 1;
      notifyListeners();
      return;
    }
    final tolerance = math.min(_finalStep / maxTravel, 0.01);
    _simulation = SpringSimulation(
      spring,
      0,
      1,
      carried,
      tolerance: Tolerance(distance: tolerance, velocity: tolerance),
    );
    _ticker
      ..stop()
      ..start();
    notifyListeners();
  }

  double _elapsedSeconds = 0;

  void _tick(Duration elapsed) {
    final simulation = _simulation;
    if (simulation == null) return;
    _elapsedSeconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    if (simulation.isDone(_elapsedSeconds)) {
      _progress = 1;
      _simulation = null;
      _ticker.stop();
    } else {
      _progress = simulation.x(_elapsedSeconds);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
