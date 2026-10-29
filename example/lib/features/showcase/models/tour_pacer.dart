import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Thrown into the waits of a [TourPacer] that was cancelled.
class TourCancelled implements Exception {
  /// Creates the exception.
  const TourCancelled();

  @override
  String toString() => 'TourCancelled';
}

/// Timed waits of a scripted sequence (the guided tour, a run of the order, a camera move) that
/// can all be cancelled at once: every pending and later wait then fails with [TourCancelled], so
/// the script stops at its next `await` and its `finally` blocks run.
class TourPacer {
  final Map<Completer<void>, VoidCallback> _pending = {};
  bool _cancelled = false;

  /// Whether [cancel] was called.
  bool get isCancelled => _cancelled;

  /// Completes after [duration].
  Future<void> wait(Duration duration) {
    if (_cancelled) return Future.error(const TourCancelled());
    final completer = Completer<void>();
    final timer = Timer(duration, () => _finish(completer));
    _pending[completer] = timer.cancel;
    return completer.future;
  }

  /// Completes once [read] returns a new value after [source] fires and then stays the same for
  /// [quiet], or after [timeout] at the latest.
  Future<void> settle(
    Listenable source,
    Object? Function() read, {
    required Duration quiet,
    required Duration timeout,
  }) {
    if (_cancelled) return Future.error(const TourCancelled());
    final completer = Completer<void>();
    var last = read();
    Timer? debounce;
    void onChange() {
      final current = read();
      if (identical(current, last)) return;
      last = current;
      debounce?.cancel();
      debounce = Timer(quiet, () => _finish(completer));
    }

    final deadline = Timer(timeout, () => _finish(completer));
    source.addListener(onChange);
    _pending[completer] = () {
      deadline.cancel();
      debounce?.cancel();
      source.removeListener(onChange);
    };
    return completer.future;
  }

  /// Cancels every pending wait and fails every later one.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final pending = Map.of(_pending);
    _pending.clear();
    for (final MapEntry(key: completer, value: release) in pending.entries) {
      release();
      completer.completeError(const TourCancelled());
    }
  }

  void _finish(Completer<void> completer) {
    final release = _pending.remove(completer);
    if (release == null) return;
    release();
    completer.complete();
  }
}
