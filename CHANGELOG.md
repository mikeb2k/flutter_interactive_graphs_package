## 0.1.0

First release: a Flutter port of [Kuiver](https://github.com/justdeko/kuiver).

* Immutable `Graph` with `GraphBuilder`, edge classification, strongly connected components,
  cycle checks and topological order.
* `HierarchicalLayout`, `ForceDirectedLayout` and custom `LayoutConfig.custom` layouts; large
  layouts run on a background isolate.
* `GraphViewer` and `GraphViewerController`: measured nodes, animated layout changes, fit to
  content, pinch / trackpad / scroll zoom and pan, animated camera.
* Edges: straight, curved, self loop, orthogonal and right-angle shapes, labels, custom arrow
  painters, parallel edge fan-out, per-edge widgets (`StyledEdge`, `EdgeLine`) or a batched painter.
* Anchors (`GraphAnchor`), node and edge selection and hover, node drag with relayout policies.
* `GraphTheme` for colors and label style.
