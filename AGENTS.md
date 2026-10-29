# interactive_graphs — agent instructions

A Flutter package for interactive directed graphs (a Dart port of [Kuiver](https://github.com/justdeko/kuiver)), plus an `example/` app with the showcase, playground and stress-test screens. Conventions are enforced by tools (`flutter analyze`, the lints in each `analysis_options.yaml`, tests). Treat a failing check as a design signal, never as something to bypass.

## Repo map

| Path                     | Role                                                                                                   |
| ------------------------ | ------------------------------------------------------------------------------------------------------ |
| `lib/interactive_graphs.dart` | The only barrel. Everything public is exported here                                               |
| `lib/src/model/`         | `Graph`, `GraphNode`, `GraphEdge`, `GraphBuilder`, edge classification, cycles, topological order: pure Dart |
| `lib/src/layout/`        | `LayoutConfig` and the algorithms (`HierarchicalLayout`, `ForceDirectedLayout`, custom providers): pure Dart |
| `lib/src/edges/`         | Edge geometry (`EdgePath`, `EdgePathFactory`), hit testing, labels, arrows, `EdgeStyle`, painting       |
| `lib/src/viewer/`        | `GraphViewerController`, `GraphInteraction`, `GraphViewer` widget, node layer, anchors, transitions    |
| `lib/src/theme/`         | `GraphTheme` / `GraphThemeData` (default colors, label style)                                          |
| `example/`               | Demo app (`interactive_graphs_example`): web, Android, iOS, macOS, Linux, Windows                     |

## How the parts talk

- Dependencies point one way: `viewer` → `edges`, `layout`, `theme` → `model`. `model` and `layout` import no Flutter UI (only `dart:ui` geometry types `Offset`/`Size`/`Rect`), so they run in an isolate and in plain unit tests.
- The package depends on `flutter/widgets.dart` only, never on `material_ui` / `cupertino_ui`: it must work in any app. The example uses `material_ui`.
- Graph space is logical pixels. Node `position` is the node's center. The viewer maps the center of the node positions to the viewport center, then applies `scale` (about the viewport center) and `offset`.

## Commands

Run from the repo root and from `example/` (there is no workspace runner):

```bash
flutter pub get
flutter analyze && flutter test
dart format -l 120 lib test
```

Example run: `cd example && flutter run -d chrome` (or any device). Web build for screenshots: `cd example && flutter build web`.

A change is done when `flutter analyze` and `flutter test` pass at the root, and in `example/` when the package's public API changed.

Finish every code change with the cheap subagents, in order, and fix what they report on the main model:

1. `checker` (Haiku): format, analyze, test in the touched targets.
2. `rules-reviewer` (Haiku): diff against the hard rules and `.claude/rules`.
3. `example-verifier` (Sonnet): only when the change is visible on screen and a device (Chrome, desktop or emulator) is available.

Rerun only the agent whose findings you fixed.

## Hard rules (whole repo)

1. The package imports `package:flutter/widgets.dart`, `foundation.dart`, `gestures.dart`, `rendering.dart`, `scheduler.dart`, `physics.dart`, `services.dart` only — never `material.dart` / `cupertino.dart` / `material_ui`. The example imports `package:material_ui/material_ui.dart` instead of `package:flutter/material.dart`.
2. `model/` and `layout/` stay free of widgets, `BuildContext` and `ChangeNotifier`: pure functions over immutable data.
3. TDD for logic: write the failing test first. Never weaken a lint or add `// ignore:` to make code pass.
4. Every color the package draws has a default in `GraphThemeData` and is overridable (theme or parameter). No raw `Color(0x…)` anywhere else in `lib/`; the example takes colors from `Theme.of(context).colorScheme`.
5. Public API is documented (`///`) and exported from the barrel (`@internal` classes are not); breaking changes bump `version` and get a `CHANGELOG.md` entry.
6. Never use global variables, constants or functions: make them members of the class that uses them (or an extension), `static` only when public or inside a static-only class. Only `main()` and Riverpod providers (example only) are top-level. Typedefs are fine. See `.claude/rules/flutter.md`.
7. Any UI / UX work (the example screens, default node/edge/label visuals) starts with the `ui-ux-pro-max:ui-ux-pro-max` skill. See `.claude/rules/ui-ux.md`.
8. Conventional Commits, small and focused. Never use `--no-verify`.
9. Analyze the request first with `superpowers:brainstorming` and ask the user about anything unclear before implementing. See `.claude/rules/requirements.md`.
10. Keep `NOTICE` and the Apache-2.0 `LICENSE`: this is a derivative of Kuiver.

## Skills and subagents

- Path-scoped conventions live in `.claude/rules/*.md` and load when you touch matching files. `requirements.md` and `ui-ux.md` have no path scope and always load. `example/` has its own short `AGENTS.md`.
- Skills: `add-layout-algorithm` (new built-in layout + tests), `add-edge-shape` (new `EdgePath` variant end to end), `add-example-screen` (new demo screen in `example/`).
- `example-verifier` (Sonnet): launches the example through the Dart MCP server and reports runtime errors, overflows and layout per screen size. Read-only.
- `checker` (Haiku): runs `dart format`, `flutter analyze` and `flutter test` in the touched targets and returns only failures. Never edits source.
- `rules-reviewer` (Haiku): checks the diff against the hard rules and `.claude/rules`, returns `file:line` findings. Read-only.
- Use the built-in `Explore` agent for broad code searches. Keep requirement questions, UI/UX design, API design and fixes on the main model: subagents can't ask the user, and those calls need judgment.
- `.claude/settings.json` denies edits to lockfiles, publishing, skipping hooks and force pushes.
