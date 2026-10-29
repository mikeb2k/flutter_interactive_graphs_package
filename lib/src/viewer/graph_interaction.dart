import 'dart:ui';

import 'package:flutter/foundation.dart';

/// How a tap on a node or an edge changes the selection.
enum SelectionMode {
  /// Taps don't select.
  none,

  /// A tap selects the item alone.
  single,

  /// A tap toggles the item.
  multiple,
}

/// What happens to nodes the user (or `moveNode`) placed by hand when the graph is laid out again.
enum RelayoutPolicy {
  /// Moved nodes stay where they were put; the rest is laid out as usual.
  keepManual,

  /// A move only lasts until the next layout pass.
  relayoutAll,
}

/// Selection, hover and drag state of a viewer's nodes and edges, reachable as
/// `GraphViewerController.interaction`.
///
/// It records what a node or edge *is*, never how it looks: the `nodeBuilder` and `edgeBuilder`
/// read the same flags from their details. Nodes and edges share one selection: selecting one kind
/// clears the other. Listeners are notified when a flag changes, not while a drag moves; listen to
/// [dragOffset] for that.
class GraphInteraction extends ChangeNotifier {
  Set<String> _selectedNodeIds = const {};
  Set<String> _selectedEdgeIds = const {};
  String? _hoveredNodeId;
  String? _hoveredEdgeId;
  String? _draggedNodeId;
  final ValueNotifier<Offset> _dragOffset = ValueNotifier(Offset.zero);

  /// Ids of the selected nodes.
  Set<String> get selectedNodeIds => _selectedNodeIds;

  /// Ids of the selected edges.
  Set<String> get selectedEdgeIds => _selectedEdgeIds;

  /// Node under the pointer, `null` on touch.
  String? get hoveredNodeId => _hoveredNodeId;

  /// Edge under the pointer, `null` on touch.
  String? get hoveredEdgeId => _hoveredEdgeId;

  /// Node being dragged, or `null`.
  String? get draggedNodeId => _draggedNodeId;

  /// Whether a node is being dragged.
  bool get isDragging => _draggedNodeId != null;

  /// How far the dragged node has moved since the drag started, in graph space. Applied when
  /// painting, never written into the graph until the drag ends.
  ValueListenable<Offset> get dragOffset => _dragOffset;

  /// Whether node [id] is selected.
  bool isSelected(String id) => _selectedNodeIds.contains(id);

  /// Whether edge [id] is selected.
  bool isEdgeSelected(String id) => _selectedEdgeIds.contains(id);

  /// Selects node [id] alone.
  void select(String id) => _set(nodes: {id}, edges: const {});

  /// Selects edge [id] alone.
  void selectEdge(String id) => _set(nodes: const {}, edges: {id});

  /// Replaces the selection with the nodes [ids].
  void selectAll(Set<String> ids) => _set(nodes: Set.unmodifiable(ids), edges: const {});

  /// Replaces the selection with the edges [ids].
  void selectAllEdges(Set<String> ids) => _set(nodes: const {}, edges: Set.unmodifiable(ids));

  /// Toggles node [id], keeping the other selected nodes.
  void toggleSelection(String id) => _set(
    nodes: _selectedNodeIds.contains(id) ? _selectedNodeIds.difference({id}) : {..._selectedNodeIds, id},
    edges: _selectedEdgeIds,
  );

  /// Toggles edge [id], keeping the other selected edges.
  void toggleEdgeSelection(String id) => _set(
    nodes: _selectedNodeIds,
    edges: _selectedEdgeIds.contains(id) ? _selectedEdgeIds.difference({id}) : {..._selectedEdgeIds, id},
  );

  /// Deselects everything.
  void clearSelection() => _set(nodes: const {}, edges: const {});

  /// Applies a tap on node [id] under [mode].
  @internal
  void tapNode(String id, SelectionMode mode) {
    switch (mode) {
      case SelectionMode.none:
        return;
      case SelectionMode.single:
        select(id);
      case SelectionMode.multiple:
        toggleSelection(id);
    }
  }

  /// Applies a tap on edge [id] under [mode].
  @internal
  void tapEdge(String id, SelectionMode mode) {
    switch (mode) {
      case SelectionMode.none:
        return;
      case SelectionMode.single:
        selectEdge(id);
      case SelectionMode.multiple:
        toggleEdgeSelection(id);
    }
  }

  /// Applies a tap on the empty canvas: clears what the modes let taps select.
  @internal
  void tapCanvas(SelectionMode nodeMode, SelectionMode edgeMode) => _set(
    nodes: nodeMode == SelectionMode.none ? _selectedNodeIds : const {},
    edges: edgeMode == SelectionMode.none ? _selectedEdgeIds : const {},
  );

  /// Sets the hovered node.
  @internal
  set hoveredNodeId(String? id) {
    if (_hoveredNodeId == id) return;
    _hoveredNodeId = id;
    notifyListeners();
  }

  /// Sets the hovered edge.
  @internal
  set hoveredEdgeId(String? id) {
    if (_hoveredEdgeId == id) return;
    _hoveredEdgeId = id;
    notifyListeners();
  }

  /// Live displacement of node [id]: the drag offset for the dragged node, zero otherwise.
  @internal
  Offset dragOffsetOf(String id) => _draggedNodeId == id ? _dragOffset.value : Offset.zero;

  /// Starts dragging node [id].
  @internal
  void startDrag(String id) {
    _dragOffset.value = Offset.zero;
    if (_draggedNodeId == id) return;
    _draggedNodeId = id;
    notifyListeners();
  }

  /// Moves the dragged node by [delta] (graph space).
  @internal
  void dragBy(Offset delta) {
    if (_draggedNodeId != null) _dragOffset.value += delta;
  }

  /// Ends the drag.
  @internal
  void endDrag() {
    _dragOffset.value = Offset.zero;
    if (_draggedNodeId == null) return;
    _draggedNodeId = null;
    notifyListeners();
  }

  /// Drops every reference to nodes not in [nodeIds] and edges not in [edgeIds].
  @internal
  void retain(Set<String> nodeIds, Set<String> edgeIds) {
    var changed = false;
    if (_selectedNodeIds.any((id) => !nodeIds.contains(id))) {
      _selectedNodeIds = Set.unmodifiable(_selectedNodeIds.intersection(nodeIds));
      changed = true;
    }
    if (_selectedEdgeIds.any((id) => !edgeIds.contains(id))) {
      _selectedEdgeIds = Set.unmodifiable(_selectedEdgeIds.intersection(edgeIds));
      changed = true;
    }
    if (_hoveredNodeId != null && !nodeIds.contains(_hoveredNodeId)) {
      _hoveredNodeId = null;
      changed = true;
    }
    if (_hoveredEdgeId != null && !edgeIds.contains(_hoveredEdgeId)) {
      _hoveredEdgeId = null;
      changed = true;
    }
    if (_draggedNodeId != null && !nodeIds.contains(_draggedNodeId)) {
      _draggedNodeId = null;
      _dragOffset.value = Offset.zero;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void _set({required Set<String> nodes, required Set<String> edges}) {
    if (setEquals(nodes, _selectedNodeIds) && setEquals(edges, _selectedEdgeIds)) return;
    _selectedNodeIds = nodes;
    _selectedEdgeIds = edges;
    notifyListeners();
  }

  @override
  void dispose() {
    _dragOffset.dispose();
    super.dispose();
  }
}
