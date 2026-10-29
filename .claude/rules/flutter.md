---
paths:
  - '**/*.dart'
  - '**/pubspec.yaml'
---

# Dart and Flutter (whole repo)

- Flutter `>=3.47`, Dart `^3.13`. Use current language features: patterns and `switch` expressions, sealed classes, records, null-aware elements (`?widget` in lists), primary constructors where they fit.
- The package (`lib/`) imports only the Flutter libraries listed in hard rule 1 (`widgets`, `foundation`, `gestures`, `rendering`, `scheduler`, `physics`, `services`) and `package:meta`; `material_ui` only in `lib/src/theme/`. The example imports `package:material_ui/material_ui.dart` / `package:cupertino_ui/cupertino_ui.dart`, never `package:flutter/material.dart` / `cupertino.dart`.
- Imports are absolute `package:` imports, also inside the same package. Only `part` / `part of` use relative paths.
- Formatting: `dart format -l 120` (`page_width: 120`, `trailing_commas: preserve`). The const lints are warnings: add `const` wherever the analyzer asks.
- No global variables, constants or functions: helpers, constants and pure logic are members of the class that uses them (or an extension), `static` only when public. Typedefs are fine. Only exceptions: `main()` and Riverpod providers in the example. In tests, helpers are local functions inside `main()`.
- Private members (`_x`) are never `static`: make them instance methods, fields or getters. Only exception: static-only classes (the layout algorithms, `EdgePathFactory`, `EdgeGeometry`) and members used where no instance exists (constructor initializer lists).
- No inline ternaries (`a ? b : c`) inside `build`: move them into a helper method declared below `build`. All helpers of a widget go below `build`, never above it.
- No `print` / `debugPrint`: report through a callback or `FlutterError.reportError`.
- No code generation in the package (no Freezed, no build_runner): model classes are hand-written immutable classes with `==`, `hashCode` and `copyWith`. They are never serialized; if JSON ever becomes a feature, it goes through Freezed in a separate library.
- Dependencies: use the latest version (`flutter pub add <pkg>`), never `any`. The package keeps its dependencies to `flutter`, `material_ui` and `meta`; ask before adding one.

## Tests

- Pure logic (model, layouts, edge geometry, hit testing) gets unit tests; widgets get widget tests. One small test file per area, no mocking frameworks: fakes are plain classes.
- Layout tests assert properties (no overlaps, level order, determinism, bounds), not exact coordinates, unless the coordinates are the contract.
- No test reaches the network or a real device.
- After a change, hot reload or restart a running app (Dart MCP `hot_reload`) instead of assuming it updated.
