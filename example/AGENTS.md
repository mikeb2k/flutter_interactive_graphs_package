# example

Demo app for `interactive_graphs` (`interactive_graphs_example`), a port of Kuiver's sample: a guided **Showcase**, an editable **Playground** and a **Stress test** with hundreds of nodes. Entry: `lib/main.dart` (`ProviderScope`) → `lib/app.dart` (`MaterialApp`, light/dark theme).

- `lib/features/<feature>/{views,widgets,models,providers}/` one folder per screen · `lib/widgets/` widgets shared by several features · `lib/theme/` app theme.
- Depends on the package by `path: ../`; import only `package:interactive_graphs/interactive_graphs.dart`.
- Targets web, Android, iOS, macOS, Linux and Windows. Pointer-only behavior (hover, Ctrl+scroll zoom) must have a touch alternative (buttons) on mobile.

Commands: `flutter analyze && flutter test`, run with `flutter run -d chrome` (or any device).

Rules: `.claude/rules/flutter.md`, `.claude/rules/example.md`, `.claude/rules/ui-ux.md`.
