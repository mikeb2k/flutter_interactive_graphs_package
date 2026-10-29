# UI / UX design

Applies to any work that creates or changes what the user sees: an example screen, a panel or dialog, the package's default node/edge/label visuals, colors, typography, spacing, motion or copy.

- Before designing or building UI, invoke the `ui-ux-pro-max:ui-ux-pro-max` skill (plugin `ui-ux-pro-max@ui-ux-pro-max-skill`, from https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) and follow it, with Flutter as the stack. Also use it to review a UI change before calling it done.
- If the skill isn't available, stop and tell the user to install it (`/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill`, then `/plugin install ui-ux-pro-max@ui-ux-pro-max-skill`); don't design without it.
- Its output is guidance, not a license to break repo rules: in the example, map any palette or spacing it suggests onto `colorScheme` / `textTheme`; in the package, onto `ColorScheme` / `TextTheme` roles in `GraphThemeData.fromColorScheme` / `fromTheme`, which stay overridable.
- Graph-specific checks: edges stay readable over node colors in light and dark themes (contrast ≥ 3:1 for lines, 4.5:1 for label text), selection and hover are visible without relying on color alone (border width, elevation), and motion respects `MediaQuery.disableAnimations`.
