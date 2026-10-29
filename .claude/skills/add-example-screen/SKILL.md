---
name: add-example-screen
description: Adds a demo screen to the example app (feature folders, Riverpod notifier + immutable state, view with a GraphViewerController, copy class, navigation entry, widget test). Use when showcasing a package feature that the existing Showcase, Playground and Stress test screens don't cover.
---

# Add an example screen

Rules: `.claude/rules/example.md`, `.claude/rules/flutter.md`, `.claude/rules/ui-ux.md`.

0. Design it first with the `ui-ux-pro-max:ui-ux-pro-max` skill (`.claude/rules/ui-ux.md`), for phone and desktop widths.
1. Create `example/lib/features/<feature>/{views,widgets,models,providers}/` (`.gitkeep` in empty ones).
2. `models/<feature>_state.dart`: immutable state with `copyWith`. `models/<feature>_copy.dart`: `abstract final class <Feature>Copy` with every string as a `static const`.
3. Write the failing test in `example/test/<feature>_test.dart`: the notifier's transitions, then a widget test that pumps the view inside `ProviderScope` + `MaterialApp` and finds the `GraphViewer`.
4. `providers/<feature>_provider.dart`: `NotifierProvider.autoDispose<<Feature>Notifier, <Feature>State>(<Feature>Notifier.new)`.
5. `views/<feature>_view.dart`: `<Feature>View` (`ConsumerStatefulWidget`) owning the `GraphViewerController` (`initState` / `dispose`), with `static Route<void> route()`. Composes widgets from `widgets/`; no private widget classes, no `_build…` methods, no ternaries in `build`.
6. Add an entry point (button or menu item) on the Showcase screen.
7. Verify: `cd example && dart format -l 120 lib test && flutter analyze && flutter test`; then `example-verifier` if a device is available.
8. Commit: `feat(example): add <feature> screen`.
