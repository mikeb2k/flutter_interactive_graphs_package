import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:interactive_graphs/src/model/graph_node.dart';
import 'package:interactive_graphs/src/viewer/graph_interaction.dart';
import 'package:interactive_graphs/src/viewer/graph_viewer_config.dart';
import 'package:interactive_graphs/src/viewer/graph_viewer_controller.dart';
import 'package:interactive_graphs/src/viewer/registries.dart';

/// What a `nodeBuilder` gets: the node and its interaction state.
@immutable
final class NodeDetails {
  /// Creates node details.
  const NodeDetails({
    required this.node,
    this.isSelected = false,
    this.isHovered = false,
    this.isDragging = false,
  });

  /// The node, with its laid-out position and its fixed or measured size.
  final GraphNode node;

  /// Whether the node is selected.
  final bool isSelected;

  /// Whether the pointer is over the node; always `false` on touch.
  final bool isHovered;

  /// Whether the node is being dragged.
  final bool isDragging;

  @override
  bool operator ==(Object other) =>
      other is NodeDetails &&
      other.node == node &&
      other.isSelected == isSelected &&
      other.isHovered == isHovered &&
      other.isDragging == isDragging;

  @override
  int get hashCode => Object.hash(node, isSelected, isHovered, isDragging);
}

/// Builds the widget of a node.
typedef GraphNodeBuilder = Widget Function(BuildContext context, NodeDetails details);

/// A named point inside a node's widget that edges can attach to (see `GraphEdge.fromAnchor` /
/// `toAnchor`). The anchor's center is the attachment point; give it a [child] to show a handle.
///
/// Anchor ids are scoped per node. Edges whose anchor is missing attach to the node's boundary.
///
/// ```dart
/// nodeBuilder: (context, details) => SizedBox(
///   width: 120,
///   height: 60,
///   child: Stack(children: [
///     const Align(alignment: AlignmentDirectional.centerStart, child: GraphAnchor(id: 'left')),
///     const Align(alignment: AlignmentDirectional.centerEnd, child: GraphAnchor(id: 'right')),
///     Center(child: Text(details.node.id)),
///   ]),
/// ),
/// ```
class GraphAnchor extends SingleChildRenderObjectWidget {
  /// Creates an anchor. Must be placed inside a node built by a `GraphViewer`.
  const GraphAnchor({super.key, required this.id, super.child});

  /// Anchor id, unique within its node.
  final String id;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final scope = NodeScope.of(context);
    return RenderGraphAnchor(id, scope.nodeId, scope.anchors);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderGraphAnchor renderObject) {
    final scope = NodeScope.of(context);
    renderObject.update(id, scope.nodeId, scope.anchors);
  }
}

/// Render object of [GraphAnchor].
@internal
class RenderGraphAnchor extends RenderProxyBox {
  /// Creates the render object.
  RenderGraphAnchor(this._id, this._nodeId, this._anchors);

  String _id;
  String _nodeId;
  AnchorRegistry _anchors;

  void update(String id, String nodeId, AnchorRegistry anchors) {
    if (id == _id && nodeId == _nodeId && identical(anchors, _anchors)) return;
    _anchors.unregister(_nodeId, _id);
    _id = id;
    _nodeId = nodeId;
    _anchors = anchors;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    _register();
  }

  void _register() {
    RenderObject? ancestor = parent;
    while (ancestor != null && ancestor is! RenderNodeBox) {
      ancestor = ancestor.parent;
    }
    if (ancestor == null) return;
    final transform = getTransformTo(ancestor);
    _anchors.register(_nodeId, _id, MatrixUtils.transformPoint(transform, size.center(Offset.zero)));
  }

  @override
  void detach() {
    _anchors.unregister(_nodeId, _id);
    super.detach();
  }
}

/// Gives the widgets of a node access to its id and the anchor registry.
@internal
class NodeScope extends InheritedWidget {
  /// Creates the scope.
  const NodeScope({super.key, required this.nodeId, required this.anchors, required super.child});

  /// Id of the node.
  final String nodeId;

  /// Where anchors register.
  final AnchorRegistry anchors;

  /// The scope of the node [context] is in.
  static NodeScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NodeScope>();
    assert(scope != null, 'GraphAnchor must be placed inside a node built by a GraphViewer.');
    return scope!;
  }

  @override
  bool updateShouldNotify(NodeScope oldWidget) => nodeId != oldWidget.nodeId || anchors != oldWidget.anchors;
}

/// Marks the box of a node, the reference anchors measure against.
@internal
class NodeBox extends SingleChildRenderObjectWidget {
  /// Creates the marker.
  const NodeBox({super.key, super.child});

  @override
  RenderNodeBox createRenderObject(BuildContext context) => RenderNodeBox();
}

/// Render object of [NodeBox].
@internal
class RenderNodeBox extends RenderProxyBox {}

/// Hosts one node: rebuilds it when its own selection, hover or drag state changes and attaches
/// the gestures the viewer config enables.
@internal
class NodeHost extends StatefulWidget {
  /// Creates a node host.
  const NodeHost({
    super.key,
    required this.node,
    required this.fixedSize,
    required this.controller,
    required this.anchors,
    required this.config,
    required this.callbacks,
    required this.builder,
  });

  /// The laid-out node.
  final GraphNode node;

  /// Size the caller gave the node, or `null` when it is measured.
  final Size? fixedSize;

  /// The viewer's controller.
  final GraphViewerController controller;

  /// Anchor registry of the viewer.
  final AnchorRegistry anchors;

  /// Viewer configuration.
  final GraphViewerConfig config;

  /// Interaction callbacks.
  final GraphInteractionCallbacks callbacks;

  /// The caller's node builder.
  final GraphNodeBuilder builder;

  @override
  State<NodeHost> createState() => _NodeHostState();
}

class _NodeHostState extends State<NodeHost> {
  late bool _isSelected;
  late bool _isHovered;
  late bool _isDragging;
  Offset? _lastDragPosition;

  GraphInteraction get _interaction => widget.controller.interaction;

  String get _id => widget.node.id;

  @override
  void initState() {
    super.initState();
    _readFlags();
    _interaction.addListener(_onInteraction);
  }

  @override
  void didUpdateWidget(NodeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.interaction.removeListener(_onInteraction);
      _interaction.addListener(_onInteraction);
    }
    _readFlags();
  }

  @override
  void dispose() {
    _interaction.removeListener(_onInteraction);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = NodeDetails(
      node: widget.node,
      isSelected: _isSelected,
      isHovered: _isHovered,
      isDragging: _isDragging,
    );
    return NodeScope(
      nodeId: _id,
      anchors: widget.anchors,
      child: _withGestures(NodeBox(child: _sized(widget.builder(context, details)))),
    );
  }

  Widget _sized(Widget content) {
    final fixed = widget.fixedSize;
    if (fixed == null) return content;
    return SizedBox.fromSize(size: fixed, child: content);
  }

  Widget _withGestures(Widget child) {
    final config = widget.config;
    final callbacks = widget.callbacks;
    final tappable = config.selectionMode != SelectionMode.none || callbacks.handlesNodeTap;
    final longPressable = callbacks.onNodeLongPress != null;
    var result = child;
    if (tappable || longPressable || config.nodeDragEnabled) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onTap: tappable ? _onTap : null,
        onLongPress: longPressable ? _onLongPress : null,
        onPanStart: config.nodeDragEnabled ? _onPanStart : null,
        onPanUpdate: config.nodeDragEnabled ? _onPanUpdate : null,
        onPanEnd: config.nodeDragEnabled ? _onPanEnd : null,
        onPanCancel: config.nodeDragEnabled ? _onPanCancel : null,
        child: result,
      );
    }
    if (config.hoverEnabled) {
      result = MouseRegion(onEnter: _onEnter, onExit: _onExit, child: result);
    }
    return result;
  }

  void _readFlags() {
    _isSelected = _interaction.isSelected(_id);
    _isHovered = _interaction.hoveredNodeId == _id;
    _isDragging = _interaction.draggedNodeId == _id;
  }

  void _onInteraction() {
    final selected = _interaction.isSelected(_id);
    final hovered = _interaction.hoveredNodeId == _id;
    final dragging = _interaction.draggedNodeId == _id;
    if (selected == _isSelected && hovered == _isHovered && dragging == _isDragging) return;
    setState(() {
      _isSelected = selected;
      _isHovered = hovered;
      _isDragging = dragging;
    });
  }

  void _onTap() {
    _interaction.tapNode(_id, widget.config.selectionMode);
    widget.callbacks.onNodeTap?.call(widget.node);
  }

  void _onLongPress() => widget.callbacks.onNodeLongPress?.call(widget.node);

  void _onEnter(PointerEnterEvent event) {
    _interaction.hoveredNodeId = _id;
    _interaction.hoveredEdgeId = null;
  }

  void _onExit(PointerExitEvent event) {
    if (_interaction.hoveredNodeId == _id) _interaction.hoveredNodeId = null;
  }

  void _onPanStart(DragStartDetails details) {
    _lastDragPosition = details.globalPosition;
    _interaction.startDrag(_id);
    widget.callbacks.onNodeDragStart?.call(widget.node);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final last = _lastDragPosition ?? details.globalPosition;
    _lastDragPosition = details.globalPosition;
    // Screen pixels to graph space; the node moves under the pointer, so local deltas would not
    _interaction.dragBy((details.globalPosition - last) / widget.controller.scale);
    widget.callbacks.onNodeDrag?.call(widget.node, _interaction.dragOffset.value);
  }

  void _onPanEnd(DragEndDetails details) {
    final travelled = _interaction.dragOffset.value;
    final node = widget.node;
    widget.controller.moveNodeBy(_id, travelled);
    _interaction.endDrag();
    _lastDragPosition = null;
    widget.callbacks.onNodeDragEnd?.call(node, travelled);
  }

  void _onPanCancel() {
    _lastDragPosition = null;
    _interaction.endDrag();
  }
}

/// Parent data of a node in a [NodeLayer].
@internal
class NodeLayerParentData extends ContainerBoxParentData<RenderBox> {
  /// Id of the node.
  String? nodeId;

  /// Fixed size, or `null` when the node is measured.
  Size? fixedSize;
}

/// Tags a child of [NodeLayer] with its node id and fixed size.
@internal
class NodeSlot extends ParentDataWidget<NodeLayerParentData> {
  /// Creates a slot.
  const NodeSlot({super.key, required this.nodeId, required this.fixedSize, required super.child});

  /// Id of the node.
  final String nodeId;

  /// Fixed size, or `null` when the node is measured.
  final Size? fixedSize;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as NodeLayerParentData;
    if (data.nodeId == nodeId && data.fixedSize == fixedSize) return;
    data
      ..nodeId = nodeId
      ..fixedSize = fixedSize;
    renderObject.parent?.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => NodeLayer;
}

/// Lays out the nodes: measured ones with unbounded constraints, fixed ones at their size, each
/// centered on its current (animated) position. Re-places them whenever [positions] fires.
@internal
class NodeLayer extends MultiChildRenderObjectWidget {
  /// Creates the layer.
  const NodeLayer({
    super.key,
    required this.centerOf,
    required this.positions,
    required this.onMeasured,
    required super.children,
  });

  /// Center of node `id` in layer coordinates.
  final Offset Function(String id) centerOf;

  /// Fires when node positions move (layout transition, drag).
  final Listenable positions;

  /// Receives the sizes of all measured nodes whenever they change.
  final ValueChanged<Map<String, Size>> onMeasured;

  @override
  RenderNodeLayer createRenderObject(BuildContext context) =>
      RenderNodeLayer(centerOf: centerOf, positions: positions, onMeasured: onMeasured);

  @override
  void updateRenderObject(BuildContext context, RenderNodeLayer renderObject) {
    renderObject
      ..centerOf = centerOf
      ..positions = positions
      ..onMeasured = onMeasured;
  }
}

/// Render object of [NodeLayer].
@internal
class RenderNodeLayer extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, NodeLayerParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, NodeLayerParentData> {
  /// Creates the render object.
  RenderNodeLayer({
    required this._centerOf,
    required this._positions,
    required this.onMeasured,
  });

  Offset Function(String id) _centerOf;
  Listenable _positions;

  /// Receives measured sizes.
  ValueChanged<Map<String, Size>> onMeasured;

  Map<String, Size> _reported = const {};

  /// Center of a node in layer coordinates.
  set centerOf(Offset Function(String id) value) {
    if (identical(value, _centerOf)) return;
    _centerOf = value;
    markNeedsLayout();
  }

  /// Fires when positions change.
  set positions(Listenable value) {
    if (identical(value, _positions)) return;
    if (attached) {
      _positions.removeListener(markNeedsLayout);
      value.addListener(markNeedsLayout);
    }
    _positions = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! NodeLayerParentData) child.parentData = NodeLayerParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _positions.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _positions.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    final measured = <String, Size>{};
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as NodeLayerParentData;
      final fixed = data.fixedSize;
      child.layout(fixed == null ? const BoxConstraints() : BoxConstraints.tight(fixed), parentUsesSize: true);
      final id = data.nodeId;
      if (id != null) {
        if (fixed == null) measured[id] = child.size;
        data.offset = _centerOf(id) - child.size.center(Offset.zero);
      }
      child = data.nextSibling;
    }
    if (!mapEquals(measured, _reported)) {
      _reported = measured;
      final callback = onMeasured;
      // Reported after layout: the controller may not rebuild anything mid-frame
      scheduleMicrotask(() => callback(measured));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
