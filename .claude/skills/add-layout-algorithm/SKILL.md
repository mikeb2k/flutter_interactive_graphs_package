---
name: add-layout-algorithm
description: Adds a built-in graph layout algorithm to interactive_graphs (config class, static-only algorithm, dispatcher case, tests, docs). Use when a new way of positioning nodes should ship with the package rather than as a user's CustomLayoutConfig.
---

# Add a layout algorithm

Rules: `.claude/rules/library.md`, `.claude/rules/flutter.md`.

0. Check it isn't better as a `CustomLayoutConfig` example: built-ins are for layouts most users want. Ask the user if unsure.
1. Write the failing tests first in `test/layout/<name>_layout_test.dart`: empty graph, single node, a DAG, a cycle, a self-loop, disconnected nodes, explicit node sizes; assert properties (no overlapping node boxes, order along the flow direction, determinism: two runs give equal graphs, the input is unchanged, every edge comes back classified).
2. Add `final class <Name>LayoutConfig extends LayoutConfig` in `lib/src/layout/layout_config.dart` with `const` constructor, documented defaults, `width`/`height`, `copyWithCanvas`, `==`/`hashCode`, plus a `const factory LayoutConfig.<name>(…)` redirect.
3. Implement `abstract final class <Name>Layout` in `lib/src/layout/<name>_layout.dart` with `static Graph run(Graph graph, <Name>LayoutConfig config, {void Function()? checkCancelled})`. Pure Dart: no widgets, logical pixels, node `position` = center, result built with `Graph.withClassifiedEdges`.
4. Add the case to `GraphLayout.run` (the `switch` is exhaustive, so the analyzer points at it).
5. Export the new file from `lib/interactive_graphs.dart`, document it in the README "Layouts" section, add a `CHANGELOG.md` entry.
6. Offer it in the example Playground's layout picker.
7. Verify: `dart format -l 120 lib test && flutter analyze && flutter test`, then `cd example && flutter analyze`.
8. Commit: `feat(layout): add <name> layout`.
