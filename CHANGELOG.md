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
* Anchors (`GraphAnchor`, `GraphEdge.withAnchors`), node and edge selection and hover, node drag
  with relayout policies.
* Follows the app's Material theme: `GraphThemeData` is a `ThemeExtension` derived from the
  `ColorScheme` and `TextTheme` (`GraphThemeData.fromTheme`), overridable per app (theme
  extension) or per subtree (`GraphTheme`). `EdgeLabelStyle.fontSize` defaults to the theme's
  label size.
* `HierarchicalLayout.run` polls `checkCancelled` like the force-directed layout.
* `CurvedEdgePath` and `SelfLoopEdgePath` share the sealed `QuadraticEdgePath` base.
