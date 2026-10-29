import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:material_ui/material_ui.dart';

/// Fixed settings of the playground screen.
abstract final class PlaygroundDefaults {
  /// Below this width the screen uses its compact layout.
  static const double compactWidth = 600;

  /// How long the screen waits for a newly picked layout before it recenters anyway.
  static const Duration recenterTimeout = Duration(seconds: 2);

  /// Pause between two auto-generation steps.
  static const Duration generateInterval = Duration(seconds: 1);

  /// Distance one arrow key pans, in logical pixels.
  static const double panStep = 48;

  /// Expand and collapse of the overlay panels.
  static const Duration panelDuration = Duration(milliseconds: 200);

  /// Zoom and pan: critically damped, settles in about 250 ms without overshoot (Kuiver uses a
  /// 250 ms tween here).
  static const SpringDescription zoomSpring = SpringDescription(mass: 1, stiffness: 400, damping: 40);

  /// Viewer configuration, with or without the debug bounds.
  static GraphViewerConfig viewerConfig({required bool showDebugBounds}) => GraphViewerConfig(
    showDebugBounds: showDebugBounds,
    contentPadding: 0.7,
    maxScale: 2,
    animateInitialPlacement: true,
    transformSpring: zoomSpring,
    selectionMode: SelectionMode.single,
    nodeDragEnabled: true,
    hoverEnabled: true,
    edgeSelectionMode: SelectionMode.single,
    edgeHoverEnabled: true,
  );

  /// Animation length of panels, zero when the platform asks for reduced motion.
  static Duration panelDurationOf(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return panelDuration;
  }
}
