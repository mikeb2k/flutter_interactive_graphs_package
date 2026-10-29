import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:interactive_graphs/src/model/graph_edge.dart';
import 'package:interactive_graphs/src/model/graph_node.dart';
import 'package:interactive_graphs/src/viewer/graph_interaction.dart';

/// Decides whether a scroll event zooms (instead of panning).
typedef ScrollZoomCondition = bool Function(PointerScrollEvent event);

/// How a `GraphViewer` looks and what it lets the user do.
///
/// Pan and zoom are always on. Selection, drag and hover are off by default: each adds its gesture
/// handling only when enabled.
@immutable
final class GraphViewerConfig {
  /// Creates a viewer configuration.
  const GraphViewerConfig({
    this.showDebugBounds = false,
    this.fitToContent = true,
    this.contentPadding = 0.8,
    this.minScale = 0.1,
    this.maxScale = 5,
    this.zoomStep = 1.2,
    this.scrollPanSpeed = 1,
    this.scrollZoomSpeed = 0.002,
    this.scrollZoomCondition = defaultScrollZoomCondition,
    this.selectionMode = SelectionMode.none,
    this.nodeDragEnabled = false,
    this.hoverEnabled = false,
    this.edgeSelectionMode = SelectionMode.none,
    this.edgeHoverEnabled = false,
    this.edgeHitTolerance = 8,
    this.relayoutPolicy = RelayoutPolicy.keepManual,
    this.transformSpring = defaultTransformSpring,
    this.layoutSpring = defaultLayoutSpring,
    this.animateLayout = true,
    this.animateInitialPlacement = false,
    this.enterDuration = Duration.zero,
  }) : assert(minScale > 0 && minScale <= maxScale),
       assert(contentPadding > 0 && contentPadding <= 1),
       assert(zoomStep > 1);

  /// Zoom and pan animations: a bouncy spring, like Compose's medium-bouncy, medium-stiffness one.
  static const SpringDescription defaultTransformSpring = SpringDescription(
    mass: 1,
    stiffness: 1500,
    damping: 38.7298334621,
  );

  /// Layout changes: a bouncy, soft spring, like Compose's medium-bouncy, low-stiffness one.
  static const SpringDescription defaultLayoutSpring = SpringDescription(
    mass: 1,
    stiffness: 200,
    damping: 14.1421356237,
  );

  /// Ctrl+scroll zooms (Cmd+scroll too on Apple keyboards); plain scroll pans.
  static bool defaultScrollZoomCondition(PointerScrollEvent event) =>
      HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

  /// Draws the graph bounds and the viewport outline.
  final bool showDebugBounds;

  /// Scales the graph to fit the viewport once it is first laid out.
  final bool fitToContent;

  /// Fraction of the viewport the fitted graph fills.
  final double contentPadding;

  /// Lowest zoom level.
  final double minScale;

  /// Highest zoom level.
  final double maxScale;

  /// Factor of one `zoomIn` / `zoomOut`.
  final double zoomStep;

  /// Logical pixels panned per pixel of scroll.
  final double scrollPanSpeed;

  /// Zoom per pixel of scroll: the scale changes by `exp(-delta * scrollZoomSpeed)`.
  final double scrollZoomSpeed;

  /// When a scroll event zooms instead of panning.
  final ScrollZoomCondition scrollZoomCondition;

  /// Whether and how tapping a node selects it.
  final SelectionMode selectionMode;

  /// Whether nodes can be dragged to a new position.
  final bool nodeDragEnabled;

  /// Whether the pointer entering a node updates `hoveredNodeId`.
  final bool hoverEnabled;

  /// Whether and how tapping an edge selects it.
  final SelectionMode edgeSelectionMode;

  /// Whether the pointer moving over an edge updates `hoveredEdgeId`.
  final bool edgeHoverEnabled;

  /// How far from an edge (in screen pixels) a tap or hover still hits it.
  final double edgeHitTolerance;

  /// What happens to dragged nodes on the next layout pass.
  final RelayoutPolicy relayoutPolicy;

  /// Spring of animated zoom and pan.
  final SpringDescription transformSpring;

  /// Spring that moves nodes when the layout changes.
  final SpringDescription layoutSpring;

  /// Whether layout changes move the nodes along [layoutSpring]; `false` makes them jump.
  final bool animateLayout;

  /// Whether the first placement animates too.
  final bool animateInitialPlacement;

  /// Fade-in of the graph once it is laid out and fitted; [Duration.zero] shows it at once.
  final Duration enterDuration;

  /// Returns a copy with the given fields replaced.
  GraphViewerConfig copyWith({
    bool? showDebugBounds,
    bool? fitToContent,
    double? contentPadding,
    double? minScale,
    double? maxScale,
    double? zoomStep,
    double? scrollPanSpeed,
    double? scrollZoomSpeed,
    ScrollZoomCondition? scrollZoomCondition,
    SelectionMode? selectionMode,
    bool? nodeDragEnabled,
    bool? hoverEnabled,
    SelectionMode? edgeSelectionMode,
    bool? edgeHoverEnabled,
    double? edgeHitTolerance,
    RelayoutPolicy? relayoutPolicy,
    SpringDescription? transformSpring,
    SpringDescription? layoutSpring,
    bool? animateLayout,
    bool? animateInitialPlacement,
    Duration? enterDuration,
  }) => GraphViewerConfig(
    showDebugBounds: showDebugBounds ?? this.showDebugBounds,
    fitToContent: fitToContent ?? this.fitToContent,
    contentPadding: contentPadding ?? this.contentPadding,
    minScale: minScale ?? this.minScale,
    maxScale: maxScale ?? this.maxScale,
    zoomStep: zoomStep ?? this.zoomStep,
    scrollPanSpeed: scrollPanSpeed ?? this.scrollPanSpeed,
    scrollZoomSpeed: scrollZoomSpeed ?? this.scrollZoomSpeed,
    scrollZoomCondition: scrollZoomCondition ?? this.scrollZoomCondition,
    selectionMode: selectionMode ?? this.selectionMode,
    nodeDragEnabled: nodeDragEnabled ?? this.nodeDragEnabled,
    hoverEnabled: hoverEnabled ?? this.hoverEnabled,
    edgeSelectionMode: edgeSelectionMode ?? this.edgeSelectionMode,
    edgeHoverEnabled: edgeHoverEnabled ?? this.edgeHoverEnabled,
    edgeHitTolerance: edgeHitTolerance ?? this.edgeHitTolerance,
    relayoutPolicy: relayoutPolicy ?? this.relayoutPolicy,
    transformSpring: transformSpring ?? this.transformSpring,
    layoutSpring: layoutSpring ?? this.layoutSpring,
    animateLayout: animateLayout ?? this.animateLayout,
    animateInitialPlacement: animateInitialPlacement ?? this.animateInitialPlacement,
    enterDuration: enterDuration ?? this.enterDuration,
  );

  @override
  bool operator ==(Object other) =>
      other is GraphViewerConfig &&
      other.showDebugBounds == showDebugBounds &&
      other.fitToContent == fitToContent &&
      other.contentPadding == contentPadding &&
      other.minScale == minScale &&
      other.maxScale == maxScale &&
      other.zoomStep == zoomStep &&
      other.scrollPanSpeed == scrollPanSpeed &&
      other.scrollZoomSpeed == scrollZoomSpeed &&
      other.scrollZoomCondition == scrollZoomCondition &&
      other.selectionMode == selectionMode &&
      other.nodeDragEnabled == nodeDragEnabled &&
      other.hoverEnabled == hoverEnabled &&
      other.edgeSelectionMode == edgeSelectionMode &&
      other.edgeHoverEnabled == edgeHoverEnabled &&
      other.edgeHitTolerance == edgeHitTolerance &&
      other.relayoutPolicy == relayoutPolicy &&
      other.transformSpring == transformSpring &&
      other.layoutSpring == layoutSpring &&
      other.animateLayout == animateLayout &&
      other.animateInitialPlacement == animateInitialPlacement &&
      other.enterDuration == enterDuration;

  @override
  int get hashCode => Object.hashAll([
    showDebugBounds,
    fitToContent,
    contentPadding,
    minScale,
    maxScale,
    zoomStep,
    scrollPanSpeed,
    scrollZoomSpeed,
    scrollZoomCondition,
    selectionMode,
    nodeDragEnabled,
    hoverEnabled,
    edgeSelectionMode,
    edgeHoverEnabled,
    edgeHitTolerance,
    relayoutPolicy,
    transformSpring,
    layoutSpring,
    animateLayout,
    animateInitialPlacement,
    enterDuration,
  ]);
}

/// What the viewer reports while the user works with the graph. All optional: selection, hover
/// and drag are tracked in `GraphInteraction` already, these are for side effects.
@immutable
final class GraphInteractionCallbacks {
  /// Creates callbacks.
  const GraphInteractionCallbacks({
    this.onNodeTap,
    this.onNodeLongPress,
    this.onNodeDragStart,
    this.onNodeDrag,
    this.onNodeDragEnd,
    this.onEdgeTap,
    this.onCanvasTap,
  });

  /// A node was tapped.
  final ValueChanged<GraphNode>? onNodeTap;

  /// A node was long-pressed.
  final ValueChanged<GraphNode>? onNodeLongPress;

  /// A node drag passed the touch slop.
  final ValueChanged<GraphNode>? onNodeDragStart;

  /// The dragged node moved; the offset is its total displacement so far, in graph space.
  final void Function(GraphNode node, Offset displacement)? onNodeDrag;

  /// The drag ended with the total displacement. The node has already been moved by then.
  final void Function(GraphNode node, Offset displacement)? onNodeDragEnd;

  /// An edge was tapped. Setting this makes edges tappable without `edgeSelectionMode`.
  final ValueChanged<GraphEdge>? onEdgeTap;

  /// The empty canvas was tapped (also taps on nodes that handle no gesture).
  final VoidCallback? onCanvasTap;

  /// Whether node taps are handled by a callback.
  bool get handlesNodeTap => onNodeTap != null;

  @override
  bool operator ==(Object other) =>
      other is GraphInteractionCallbacks &&
      other.onNodeTap == onNodeTap &&
      other.onNodeLongPress == onNodeLongPress &&
      other.onNodeDragStart == onNodeDragStart &&
      other.onNodeDrag == onNodeDrag &&
      other.onNodeDragEnd == onNodeDragEnd &&
      other.onEdgeTap == onEdgeTap &&
      other.onCanvasTap == onCanvasTap;

  @override
  int get hashCode =>
      Object.hash(onNodeTap, onNodeLongPress, onNodeDragStart, onNodeDrag, onNodeDragEnd, onEdgeTap, onCanvasTap);
}
