# interactive_graphs

Interactive directed graphs for Flutter: hierarchical and force-directed layouts (or your own),
pan and zoom, animated layout changes, styled and labelled edges, anchors, selection, hover and
node drag. A Dart port of [Kuiver](https://github.com/justdeko/kuiver), the Kotlin Multiplatform
graph library by Denis Koljada.

- 2 built-in layouts (hierarchical and force-directed) plus custom layouts
- Acyclic and cyclic graphs, self loops and parallel edges
- Nodes are any widgets, measured automatically
- 5 edge shapes (straight, curved, self loop, orthogonal S-curve, right angle), dashed back edges,
  custom arrow heads, labels
- Zoom and pan: pinch, trackpad, mouse drag, Ctrl+scroll, programmatic and animated
- Node and edge selection and hover, node drag with manual positions that survive re-layout
- Anchors: named attachment points inside nodes
- A batched edge painter for graphs with hundreds of nodes; large layouts run on a background
  isolate
- Follows your app's Material theme (light, dark, custom color schemes) with no setup

Platforms: Android, iOS, web, macOS, Linux, Windows.

## Installation

```bash
flutter pub add interactive_graphs
```

Requires Flutter `>=3.47.0` (Dart `^3.13`).

## Basic usage

```dart
import 'package:interactive_graphs/interactive_graphs.dart';

class OrderGraph extends StatefulWidget {
  const OrderGraph({super.key});

  @override
  State<OrderGraph> createState() => _OrderGraphState();
}

class _OrderGraphState extends State<OrderGraph> {
  late final GraphViewerController _controller = GraphViewerController(
    graph: Graph.build((g) => g
      ..nodes(['A', 'B', 'C'])
      ..edges([('A', 'B'), ('B', 'C'), ('A', 'C')])),
    layoutConfig: const LayoutConfig.hierarchical(direction: LayoutDirection.horizontal),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GraphViewer(
      controller: _controller,
      nodeBuilder: (context, details) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const ShapeDecoration(shape: StadiumBorder(), color: Color(0xFF2196F3)),
        child: Text(details.node.id),
      ),
      edgeBuilder: (context, details) => StyledEdge(details: details),
    );
  }
}
```

The viewer fills its (bounded) constraints. Graph space is logical pixels; a node's `position` is
its center.

## The graph

`Graph` is immutable and compares by value. Build one with `Graph.build`, derive new ones with
`withNode`, `withEdge`, `withoutNode`, `withoutEdge`, `rebuild`, and hand them to
`controller.updateGraph`:

```dart
final graph = Graph.build((g) => g
  ..nodes(['A', 'B'])
  ..node('C', size: const Size(120, 80)) // fixed size; others are measured
  ..edge('A', 'B', fromAnchor: 'right', toAnchor: 'left')
  ..edge('A', 'B', id: 'fallback')); // parallel edges need their own ids

controller.updateGraph(graph.rebuild((g) => g
  ..nodes(['D'])
  ..edge('C', 'D')));
```

Keep your application data elsewhere and look it up by node id in the `nodeBuilder`. Graph
algorithms: `classifyAllEdges` (forward, back, cross, self loop), `findStronglyConnectedComponents`,
`hasCycles`, `wouldCreateCycle`, `topologicalOrder`, `edgesBetween`. All traversals are iterative,
so deep graphs don't overflow the stack.

## Layouts

```dart
const LayoutConfig.hierarchical(
  direction: LayoutDirection.vertical,
  levelSpacing: 150, // grows to fit the largest node
  nodeSpacing: 100,
);

const LayoutConfig.forceDirected(iterations: 200, repulsionStrength: 500, attractionStrength: 0.02, damping: 0.85);

LayoutConfig.custom((graph, config) {
  final nodes = graph.nodes.values.toList();
  final center = config.canvasSize.center(Offset.zero);
  final radius = config.canvasSize.shortestSide * 0.4;
  return Graph.withClassifiedEdges([
    for (var i = 0; i < nodes.length; i++)
      nodes[i].copyWith(position: center + Offset.fromDirection(i / nodes.length * 2 * pi, radius)),
  ], graph.edges);
});
```

- **Hierarchical** (Sugiyama): sets back edges aside, assigns levels by longest path, reduces
  crossings with barycenter sweeps, leaves gaps where edges skip levels. Isolated nodes get a level
  of their own. Best for DAGs and trees.
- **Force-directed** (Fruchterman–Reingold): repulsion with a distance cutoff and a spatial grid
  above 128 nodes, springs, centering and a cooling schedule. Large graphs spread over larger
  bounds and the initial fit zooms out to match.
- Set `controller.layoutConfig` to switch; the nodes animate to their new places. Layouts can also
  be run directly with `GraphLayout.run(graph, config)`.

## Edges

Two ways to draw edges:

```dart
// One widget per edge: labels, custom widgets, anything
GraphViewer(
  controller: controller,
  nodeBuilder: ...,
  edgeBuilder: (context, details) => StyledEdge(
    details: details,
    label: 'ships',
    labelPlacement: LabelPlacement.center,
    labelStyle: const EdgeLabelStyle(rotateWithEdge: true),
    shape: EdgeShape.auto, // straight, curved for back edges; or curved, orthogonal, rightAngle
    strokeWidth: details.isSelected ? 4 : 2,
  ),
);

// All edges from one canvas: much cheaper for big graphs (no labels)
GraphViewer(
  controller: controller,
  nodeBuilder: ...,
  edgeStyle: (details) => EdgeStyle.styled(details.edge, baseColor: grey, backEdgeColor: red),
);
```

- `StyledEdge` is Kuiver's default look: dashed, faded back edges and dashed self loops.
  `EdgeLine(details:, style: EdgeStyle(...))` gives full control: color, width, dashes, shape,
  loop radius, arrow size and painter (`ArrowPainters.triangle`, `open`, `circle`, `none` or your
  own `ArrowPainter`).
- Parallel edges fan out automatically; nested self loops grow.
- `EdgeShape.rightAngle` routes by the anchor sides (`left`/`right`/`top`/`bottom` and synonyms).
- Fully custom edges: compute an `EdgePath` with `EdgePathFactory`, paint it, and call
  `EdgeHitScope.report(context, path)` so taps and hover hit it.

## Anchors

```dart
nodeBuilder: (context, details) => SizedBox(
  width: 120,
  height: 60,
  child: Stack(children: [
    const Align(alignment: Alignment.centerLeft, child: GraphAnchor(id: 'left')),
    const Align(alignment: Alignment.centerRight, child: GraphAnchor(id: 'right')),
    Center(child: Text(details.node.id)),
  ]),
),
```

Edges with `fromAnchor` / `toAnchor` attach to the anchor's center; edges whose anchor is missing
fall back to the node's boundary. Anchor ids are scoped per node.

## Interaction

```dart
GraphViewer(
  controller: controller,
  config: const GraphViewerConfig(
    selectionMode: SelectionMode.single, // none, single, multiple
    nodeDragEnabled: true,
    hoverEnabled: true,
    edgeSelectionMode: SelectionMode.multiple,
    edgeHoverEnabled: true,
    relayoutPolicy: RelayoutPolicy.keepManual, // dragged nodes stay put on re-layout
  ),
  callbacks: GraphInteractionCallbacks(
    onNodeTap: (node) => ...,
    onNodeLongPress: (node) => ...,
    onNodeDragEnd: (node, displacement) => ...,
    onEdgeTap: (edge) => ...,
    onCanvasTap: () => ...,
  ),
  nodeBuilder: (context, details) => MyNode(
    selected: details.isSelected,
    hovered: details.isHovered,
    dragging: details.isDragging,
  ),
);
```

State lives in `controller.interaction` (`selectedNodeIds`, `selectedEdgeIds`, `hoveredNodeId`,
`select`, `toggleSelection`, `clearSelection`, …). A node widget only rebuilds when its own flags
change. With a `selectionMode`, a node also tells screen readers whether it is selected; its
label and the rest of its semantics come from your node widget.

## Camera

`controller.centerGraph()`, `centerOn(graphPoint, scale:)`, `zoomIn()`, `zoomOut()`,
`updateTransform(scale:, offset:, animated:)`, `moveNode(id, position)`, `clearManualPositions()`,
`relayout()`, and `graphToViewport` / `viewportToGraph` to convert coordinates. When a toolbar or
a panel covers part of the viewer, reserve its room with
`controller.updateContentInsets(EdgeInsets.only(top: 64))`: `centerGraph` and `centerOn` then use
what is left. Users zoom with pinch, trackpad pinch and Ctrl (or Cmd)
+ scroll, and pan with drag, trackpad and scroll. Springs, zoom limits, fit padding and scroll
speeds are in `GraphViewerConfig`; `MediaQuery.disableAnimations` turns the animations off.

## Theming

Graphs follow the app's Material theme out of the box: edges, back edges, labels and debug
outlines take their colors from the ambient `ColorScheme`, and labels use `textTheme.labelMedium`.
Light and dark mode, `ColorScheme.fromSeed` and theme animations all carry over with no setup.

| Graph element              | Theme role                         |
| -------------------------- | ---------------------------------- |
| Edges                      | `outline`                          |
| Back edges, self loops     | `outline` faded / `error`          |
| Label text                 | `onSurface`, `textTheme.labelMedium` |
| Label background, border   | `surfaceContainerHigh`, `outlineVariant` |

To restyle every graph of the app, add a `GraphThemeData` to the theme's extensions:

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: scheme,
    extensions: [
      GraphThemeData.fromColorScheme(scheme).copyWith(backEdgeColor: scheme.tertiary),
    ],
  ),
);
```

To restyle one part of the tree, wrap it in a `GraphTheme(data: ..., child: ...)`.
`GraphTheme.of(context)` resolves in that order: the closest `GraphTheme`, then the theme
extension, then `GraphThemeData.fromTheme(Theme.of(context))`. Per-edge parameters
(`StyledEdge(baseColor: ...)`, `EdgeLabelStyle(textColor: ...)`) win over all of them.

## Node sizes

Nodes without a `size` are laid out with unbounded constraints and measured; the graph is laid out
again whenever a measured size changes. Give such widgets an intrinsic size (no top-level
`Expanded` or infinite widths). Nodes with a `size` get exactly that box.

## Large graphs

- Leave out `edgeBuilder`: the viewer then paints every edge from one canvas (style them with
  `edgeStyle`).
- Set `GraphViewerConfig(rebuildNodesOnLayout: false)` when your `nodeBuilder` doesn't read the
  node's position or size. A node is then built once, and again only when its selection, hover or
  drag state changes, instead of after every layout pass.
- Layouts of 200 nodes or more run on a background isolate (`backgroundLayoutThreshold` on the
  controller; not for custom layouts, and not on the web). In a `testWidgets` test such a layout
  only finishes inside `tester.runAsync`.
- Pan and zoom move the picture without repainting it, at any graph size.

## Example

`example/` ports Kuiver's sample: a guided **Showcase** of an order-fulfilment flow, an editable
**Playground** and a **Stress test** with hundreds of nodes.

```bash
cd example && flutter run -d chrome
```

## Coming from Kuiver

| Kuiver (Compose)                                   | interactive_graphs (Flutter)                                 |
| -------------------------------------------------- | ------------------------------------------------------------ |
| `buildKuiver { nodes(..); edges(..) }`             | `Graph.build((g) => g..nodes([..])..edges([..]))`             |
| `Kuiver`, `KuiverNode`, `KuiverEdge`               | `Graph`, `GraphNode`, `GraphEdge`                             |
| `NodeDimensions(w.dp, h.dp)`, `DpOffset`           | `Size(w, h)`, `Offset` (logical pixels)                       |
| `rememberKuiverViewerState(kuiver, layoutConfig)`  | `GraphViewerController(graph:, layoutConfig:)` in a `State`   |
| `state.updateKuiver(..)`                           | `controller.updateGraph(..)`                                  |
| `KuiverViewer(state, nodeContent, edgeContent)`    | `GraphViewer(controller:, nodeBuilder:, edgeBuilder:)`        |
| `KuiverViewer(.., edgeStyle = ..)`                 | `GraphViewer(.., edgeStyle: ..)`                              |
| `KuiverNodeScope` / `KuiverEdgeScope` receivers    | `NodeDetails` / `EdgeDetails` arguments                       |
| `StyledEdgeContent`, `EdgeContentWithLabel`, …     | `StyledEdge`, `EdgeLine` with an `EdgeShape`                  |
| `KuiverAnchor(anchorId, nodeId)`                   | `GraphAnchor(id:)` (the node is implicit)                     |
| `LocalKuiverColors provides KuiverColors(..)`      | automatic from `ThemeData`; override with a `GraphThemeData` theme extension or `GraphTheme` |
| `ArrowDrawer`                                      | `ArrowPainter`                                                |
| `AnimationSpec` in `KuiverViewerConfig`            | `SpringDescription` in `GraphViewerConfig`                    |
| `rememberSaveableKuiverViewerState`                | not ported: keep the `Graph` in your own state / restoration |

## Development

Agent instructions, rules and subagents live in `AGENTS.md` and `.claude/` (adapted from
`flutter_webshare_monorepo`).

```bash
flutter pub get
flutter analyze && flutter test
dart format -l 120 lib test
```

## License

Apache License 2.0, see `LICENSE` and `NOTICE`. Ported from
[Kuiver](https://github.com/justdeko/kuiver) © Denis Koljada, Apache License 2.0.
