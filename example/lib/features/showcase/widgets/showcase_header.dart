import 'package:interactive_graphs_example/features/showcase/models/showcase_copy.dart';
import 'package:interactive_graphs_example/features/showcase/models/showcase_layout.dart';
import 'package:interactive_graphs_example/widgets/connected_toggle_group.dart';
import 'package:material_ui/material_ui.dart';

/// Top of the showcase: title with the graph size, tour button, theme toggle, the menu with the
/// other screens, and the layout and edge style pickers in a row that scrolls on narrow screens.
class ShowcaseHeader extends StatelessWidget {
  /// Creates the header.
  const ShowcaseHeader({
    super.key,
    required this.steps,
    required this.connections,
    required this.layout,
    required this.edgeStyle,
    required this.isTouring,
    required this.isDark,
    required this.onToggleTour,
    required this.onToggleTheme,
    required this.onOpenPlayground,
    required this.onOpenStressTest,
    required this.onSelectLayout,
    required this.onSelectEdgeStyle,
  });

  /// Number of steps in the graph.
  final int steps;

  /// Number of edges in the graph.
  final int connections;

  /// Selected layout.
  final ShowcaseLayout layout;

  /// Selected edge style.
  final ShowcaseEdgeStyle edgeStyle;

  /// Whether the tour is playing.
  final bool isTouring;

  /// Whether the app is in dark mode.
  final bool isDark;

  /// Starts or stops the tour.
  final VoidCallback onToggleTour;

  /// Switches between light and dark mode.
  final VoidCallback onToggleTheme;

  /// Opens the playground.
  final VoidCallback onOpenPlayground;

  /// Opens the stress test.
  final VoidCallback onOpenStressTest;

  /// Picks a layout.
  final ValueChanged<ShowcaseLayout> onSelectLayout;

  /// Picks an edge style.
  final ValueChanged<ShowcaseEdgeStyle> onSelectEdgeStyle;

  /// Width below which the tour button shows its icon only.
  static const double compactWidth = 600;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBar(
            backgroundColor: scheme.surfaceContainerLow,
            scrolledUnderElevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ShowcaseCopy.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  ShowcaseCopy.subtitle(steps, connections),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              _tourButton(context),
              IconButton(icon: Icon(_themeIcon()), tooltip: _themeTooltip(), onPressed: onToggleTheme),
              PopupMenuButton<VoidCallback>(
                icon: const Icon(Icons.more_vert),
                tooltip: ShowcaseCopy.moreScreens,
                onSelected: _open,
                itemBuilder: _menuItems,
              ),
              const SizedBox(width: 4),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              spacing: 16,
              children: [
                ConnectedToggleGroup<ShowcaseLayout>(
                  options: ShowcaseLayout.values,
                  selected: layout,
                  label: _layoutLabel,
                  icon: _layoutIcon,
                  onSelect: onSelectLayout,
                ),
                ConnectedToggleGroup<ShowcaseEdgeStyle>(
                  options: ShowcaseEdgeStyle.values,
                  selected: edgeStyle,
                  label: _edgeStyleLabel,
                  icon: _edgeStyleIcon,
                  onSelect: onSelectEdgeStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Full button on wide screens, icon button on narrow ones.
  Widget _tourButton(BuildContext context) {
    final icon = Icon(_tourIcon());
    final label = _tourLabel();
    if (MediaQuery.sizeOf(context).width < compactWidth) {
      return IconButton.filledTonal(icon: icon, tooltip: label, onPressed: onToggleTour);
    }
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FilledButton.tonalIcon(icon: icon, label: Text(label), onPressed: onToggleTour),
    );
  }

  List<PopupMenuEntry<VoidCallback>> _menuItems(BuildContext context) => [
    PopupMenuItem(
      value: onOpenPlayground,
      child: const ListTile(leading: Icon(Icons.edit), title: Text(ShowcaseCopy.playground)),
    ),
    PopupMenuItem(
      value: onOpenStressTest,
      child: const ListTile(leading: Icon(Icons.speed), title: Text(ShowcaseCopy.stressTest)),
    ),
  ];

  void _open(VoidCallback open) => open();

  IconData _tourIcon() {
    if (isTouring) return Icons.stop;
    return Icons.play_arrow;
  }

  String _tourLabel() {
    if (isTouring) return ShowcaseCopy.stopTour;
    return ShowcaseCopy.playTour;
  }

  IconData _themeIcon() {
    if (isDark) return Icons.light_mode;
    return Icons.dark_mode;
  }

  String _themeTooltip() {
    if (isDark) return ShowcaseCopy.switchToLight;
    return ShowcaseCopy.switchToDark;
  }

  String _layoutLabel(ShowcaseLayout option) => option.label;

  IconData _layoutIcon(ShowcaseLayout option) => option.icon;

  String _edgeStyleLabel(ShowcaseEdgeStyle option) => option.label;

  IconData _edgeStyleIcon(ShowcaseEdgeStyle option) => option.icon;
}
