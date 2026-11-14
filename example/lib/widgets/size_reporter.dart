import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

/// Reports the size of [child] after every layout that changes it, once the frame is done.
class SizeReporter extends SingleChildRenderObjectWidget {
  /// Creates the reporter around [child].
  const SizeReporter({super.key, required this.onSizeChanged, required super.child});

  /// Called with the new size.
  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReporter(onSizeChanged);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    if (renderObject is _RenderSizeReporter) renderObject.onSizeChanged = onSizeChanged;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final current = size;
    if (current == _reported) return;
    _reported = current;
    SchedulerBinding.instance.addPostFrameCallback(_report);
  }

  void _report(Duration _) {
    final reported = _reported;
    if (attached && reported != null) onSizeChanged(reported);
  }
}
