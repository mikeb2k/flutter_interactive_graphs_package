## 0.2.1

* README: the demo GIF and screenshots show on pub.dev too.

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
* Performance: `HierarchicalLayout` is linear in the edges that skip levels. A random graph of
  5000 nodes and 7500 edges went from about 8 s to well under 100 ms.
* Performance: edges and nodes paint into layers of their own, so pan and zoom repaint neither
  and node selection or hover leaves the edges alone; with an `edgeBuilder` only the edges that
  moved or changed state rebuild; `updateContentInsets` rebuilds nothing.
* `GraphViewerController.backgroundLayoutThreshold` defaults to 200 (was 400), and only one
  background layout runs at a time: a newer request stops its isolate and is laid out instead.
  In a `testWidgets` test a background layout only finishes inside `tester.runAsync`; pass a
  higher threshold to keep such graphs on the UI isolate.
* `GraphViewerConfig.rebuildNodesOnLayout` (default `true`): turn it off when the `nodeBuilder`
  reads neither the node's position nor its size, and a node is built once instead of after every
  layout pass.
* Performance: a change to one node (`moveNode`, a new neighbor) no longer rebuilds the hosts of
  all the other nodes.
* `EdgePainting.line` gives the (dashed) line of an edge and `EdgePainting.paint` takes it back
  as `line`; `EdgeLine` and `StyledEdge` use it to keep the line of an edge that didn't change,
  which makes dragging a node among many edge widgets about seven times cheaper.
* Accessibility: with a `selectionMode`, a node tells assistive technology whether it is selected.
  It joins the semantics of the node's own widget (label, tap action) and replaces none of them.

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
