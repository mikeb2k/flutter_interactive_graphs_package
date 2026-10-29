import 'package:flutter/services.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs_example/features/playground/models/playground_defaults.dart';
import 'package:material_ui/material_ui.dart';

/// Keyboard control of a graph viewer: the arrow keys pan, `+` / `=` zoom in and `-` zooms out.
/// Takes the keyboard focus when a pointer goes down on [child].
class GraphKeyboardControls extends StatefulWidget {
  /// Creates the controls around [child].
  const GraphKeyboardControls({super.key, required this.controller, required this.child});

  /// The viewer to control.
  final GraphViewerController controller;

  /// The viewer.
  final Widget child;

  @override
  State<GraphKeyboardControls> createState() => _GraphKeyboardControlsState();
}

class _GraphKeyboardControlsState extends State<GraphKeyboardControls> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: Listener(behavior: HitTestBehavior.translucent, onPointerDown: _onPointerDown, child: widget.child),
    );
  }

  void _onPointerDown(PointerDownEvent event) => _focusNode.requestFocus();

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final controller = widget.controller;

    // Move the content opposite to the arrow
    final pan = _panFor(event.logicalKey);
    if (pan != null) {
      controller.updateTransform(offset: controller.offset + pan);
      return KeyEventResult.handled;
    }

    // Match the typed character too, keyboard layouts put + and - on different keys
    final key = event.logicalKey;
    final character = event.character;
    if (key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.numpadAdd ||
        character == '+' ||
        character == '=') {
      controller.zoomIn();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract || character == '-') {
      controller.zoomOut();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Offset? _panFor(LogicalKeyboardKey key) {
    const step = PlaygroundDefaults.panStep;
    if (key == LogicalKeyboardKey.arrowLeft) return const Offset(step, 0);
    if (key == LogicalKeyboardKey.arrowRight) return const Offset(-step, 0);
    if (key == LogicalKeyboardKey.arrowUp) return const Offset(0, step);
    if (key == LogicalKeyboardKey.arrowDown) return const Offset(0, -step);
    return null;
  }
}
