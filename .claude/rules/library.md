---
paths:
  - 'lib/**'
  - 'test/**'
---

# The package (lib/)

## Structure

- Code lives in `lib/src/<area>/` (`model`, `layout`, `edges`, `viewer`, `theme`); the package exposes only what `lib/interactive_graphs.dart` exports. Export every new public file there; never make users import `src/`.
- Dependency direction: `viewer` → `edges`, `layout`, `theme` → `model`. `model/` and `layout/` never import `widgets.dart`, `rendering.dart` or anything with a `BuildContext` (only `dart:ui` geometry, `dart:math`, `foundation.dart` for `@immutable` / `listEquals`).
- Use `@internal` (`package:meta`) for what other `src/` libraries need but users must not call. `@internal` classes are never exported from the barrel; `@internal` members of exported classes are fine (the analyzer warns any use outside the package). Viewer plumbing classes (render objects, registries, the layout transition) are `@internal` and stay unexported.

## Model and layouts

- `Graph` is immutable and compares structurally: every change returns a new instance (`withNode`, `withEdge`, `withoutNode`, `rebuild`), and an unchanged result returns `this`.
- Layout algorithms are static-only classes with a `run(Graph, Config)` entry point. They are deterministic (same input, same output), never mutate their input, and poll the optional `checkCancelled` callback in long loops.
- Every length is in logical pixels. Node `position` is the node center.
- Use the `add-layout-algorithm` skill for a new algorithm.

## Viewer

- State lives in `GraphViewerController` (a `ChangeNotifier`, no `TickerProvider`): it asks for animations, the `GraphViewer` state runs them. Controllers have `dispose()` and the widget never disposes a controller it didn't create.
- Rebuild as little as possible: pan, zoom and layout animation update a `RenderObject` or a `Listenable` the painter/render object listens to, not the node widgets. A node rebuilds only when its own selection/hover/drag flags change.
- Gestures: nodes win over the canvas (taps, drags); the canvas only pans/zooms past the slop. Hover is pointer-only: always keep a non-hover path for touch.
- Everything visual is overridable: colors via `GraphTheme` / parameters, node visuals via `nodeBuilder`, edges via `edgeBuilder` or `edgeStyle`, arrows via `ArrowPainter`.
- Accessibility: node content owns its semantics; the viewer adds none that would hide it. Interactive defaults keep `kMinInteractiveDimension` hit targets where the package draws its own controls.
- Use the `add-edge-shape` skill for a new edge shape.

## Release

- `version` in `pubspec.yaml` follows semver; any public API change adds a `CHANGELOG.md` entry and updates the README snippet it affects.
- Every public widget has a widget test; every public pure function or class has a unit test.
