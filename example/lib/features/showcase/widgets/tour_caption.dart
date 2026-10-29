import 'package:interactive_graphs_example/features/showcase/models/tour_text.dart';
import 'package:material_ui/material_ui.dart';

/// Caption of the guided tour, swapped with a fade and a slight zoom. Shows nothing for `null`.
class TourCaption extends StatelessWidget {
  /// Creates the caption.
  const TourCaption({super.key, required this.caption});

  /// The caption shown, none when `null`.
  final TourText? caption;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: _duration(context, 400),
        reverseDuration: _duration(context, 150),
        switchInCurve: const Interval(0.25, 1, curve: Curves.easeOut),
        transitionBuilder: _transition,
        layoutBuilder: _layout,
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final shown = caption;
    if (shown == null) return const SizedBox(key: ValueKey('none'), height: 1);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleStyle = _titleStyle(theme.textTheme, shown)?.copyWith(
      color: scheme.onSecondaryContainer,
      fontWeight: FontWeight.w700,
    );
    return ConstrainedBox(
      key: ValueKey(shown),
      constraints: const BoxConstraints(maxWidth: 560),
      child: Material(
        color: scheme.secondaryContainer,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(shown.title, textAlign: TextAlign.center, style: titleStyle),
              ),
              Text(
                shown.body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSecondaryContainer.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle? _titleStyle(TextTheme text, TourText shown) {
    if (shown.large) return text.displaySmall;
    return text.headlineSmall;
  }

  Widget _transition(Widget child, Animation<double> animation) => FadeTransition(
    opacity: animation,
    child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1).animate(animation), child: child),
  );

  Widget _layout(Widget? current, List<Widget> previous) => Stack(
    alignment: Alignment.topCenter,
    children: [...previous, ?current],
  );

  Duration _duration(BuildContext context, int millis) {
    if (MediaQuery.disableAnimationsOf(context)) return Duration.zero;
    return Duration(milliseconds: millis);
  }
}
