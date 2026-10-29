import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Light or dark theme of the whole example; follows the system until toggled.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Holds the theme mode.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Switches between light and dark, starting from what [platformBrightness] shows now.
  void toggle(Brightness platformBrightness) {
    final isDark = switch (state) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
    state = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}
