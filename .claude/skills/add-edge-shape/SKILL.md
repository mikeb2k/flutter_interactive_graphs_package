---
name: add-edge-shape
description: Adds an edge shape to interactive_graphs end to end (EdgePath variant, factory, hit testing, bounds, label positions, painting, EdgeShape enum, tests). Use when edges need a new geometry such as splines or routed polylines.
---

# Add an edge shape

Rules: `.claude/rules/library.md`, `.claude/rules/flutter.md`.

1. Write the failing tests first in `test/edges/edge_path_test.dart` (geometry: endpoint shortened for the arrow, length, label position at 0 / 0.5 / 1, bounds contain every point) and `test/edges/edge_hit_test.dart` (a point on the path hits, a point beyond tolerance doesn't).
2. Add `final class <Name>EdgePath extends EdgePath` in `lib/src/edges/edge_path.dart`. The `sealed` base makes every `switch` over `EdgePath` fail to compile until it handles the new case: `distanceTo`, `bounds`, `labelPositionAt`, `toPath` (the `dart:ui` `Path` the painter strokes) and `arrowDirection`.
3. Add `static <Name>EdgePath create<Name>(…)` to `EdgePathFactory`, reusing `EdgeGeometry` helpers.
4. Add the value to `EdgeShape` and its branch in `EdgeStyle.createPath`; decide whether parallel edges fan out with it (`EdgeShape.fansOut`).
5. If users should reach it from `edgeBuilder`, add a `shape:` option to `StyledEdge` rather than a new widget.
6. Export, README "Edges" section, `CHANGELOG.md` entry; show it in the example Playground's edge-shape picker.
7. Verify: `dart format -l 120 lib test && flutter analyze && flutter test`, then `cd example && flutter analyze`.
8. Commit: `feat(edges): add <name> edge shape`.
