---
paths:
  - 'example/**'
---

# Example app

## Layout

```
lib/
  main.dart                 runApp(ProviderScope(child: ExampleApp()))
  app.dart                  MaterialApp (light/dark theme, home: ShowcaseView)
  theme/                    AppTheme (ColorScheme.fromSeed) and graph theme mapping
  features/<feature>/       showcase, playground, stress_test
  widgets/                  widgets used by more than one feature
```

Every feature has `views/ widgets/ models/ providers/` (keep empty ones with a `.gitkeep`).

- `views/<name>_view.dart` holds the screen (`<Name>View`) only: it composes widgets and reads providers. Any widget a view uses that is more than a few lines of layout goes into `widgets/` as a public class with explicit constructor parameters. No private `_Widget` classes and no `_buildX()` methods in a view file.
- Placement by reach: used by one feature → `features/<feature>/widgets/`; by two or more → `lib/widgets/`. Features don't import each other's `widgets/`, `models/` or `providers/`.
- Navigation: each view has `static Route<void> route()`; navigate with `Navigator.of(context).push(XView.route())`. No string routes.

## State

- Screen state is a `NotifierProvider.autoDispose<XNotifier, XState>(XNotifier.new)` in the feature's `providers/`, with an immutable `XState` (hand-written `copyWith`) in `models/`. No `StateProvider`, no ad-hoc `setState` for more than one local field.
- The `GraphViewerController` belongs to the view's `State` (created in `initState`, disposed in `dispose`) and is fed from the notifier's state; the notifier never holds widgets or controllers.

## Text, colors, feedback

- User-facing strings live in one `<Feature>Copy` class per feature (`static const` members); no inline literals in `Text(`, `tooltip:`, `label:`. (The demo is English-only, so there is no l10n.)
- Colors only from `Theme.of(context).colorScheme` / `textTheme`; never `Color(0x…)` or `Colors.` in `lib/`. Node accent colors map to scheme roles (`primary`, `secondary`, `tertiary`, `error` and their containers).
- Feedback through `ScaffoldMessenger` snack bars and Material dialogs.
- Layout works from 360 px phones to wide desktop windows: panels collapse into bottom sheets or drawers on narrow screens; touch targets at least 48 px.
