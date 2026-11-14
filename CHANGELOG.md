## 0.2.0

* **Breaking:** `GraphViewerController.contentOffset` / `updateContentOffset(Offset)` are replaced
  by `contentInsets` / `updateContentInsets(EdgeInsets)`: the room overlay UI takes at each edge
  of the viewer. `centerGraph` now fits the graph into the room that is left instead of only
  shifting it. Migrate `updateContentOffset(Offset(0, top - bottom))` to
  `updateContentInsets(EdgeInsets.only(top: top, bottom: bottom))`.
* `GraphViewerController.centerOn(graphPoint, scale:, animated:)` puts a graph point in the middle
  of that room.
* Fixed: `centerGraph` centers the node bounds, so a graph whose outer nodes differ in size no
  longer ends up off center.

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
* `GraphThemeData.labelTextStyle` (12 px by default) and `labelBorderColor` (transparent for
  none) are non-nullable, so `copyWith` reaches them.
* `GraphViewerConfig.animateLayout` turns layout animation off; `layoutSpring` and
  `enterDuration` (default `Duration.zero`) are non-nullable, so `copyWith` reaches every field.
