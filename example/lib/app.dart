import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_graphs_example/app_copy.dart';
import 'package:interactive_graphs_example/features/showcase/views/showcase_view.dart';
import 'package:interactive_graphs_example/providers/theme_mode_provider.dart';
import 'package:interactive_graphs_example/theme/app_theme.dart';
import 'package:interactive_graphs_example/widgets/zoom_hint.dart';
import 'package:material_ui/material_ui.dart';

/// Root of the example: theme, graph theme and the showcase as home screen.
class ExampleApp extends ConsumerWidget {
  /// Creates the app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppCopy.title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      builder: _wrap,
      home: const ZoomHint(message: AppCopy.zoomHint, child: ShowcaseView()),
    );
  }

  Widget _wrap(BuildContext context, Widget? child) => AppGraphTheme(child: child ?? const SizedBox.shrink());
}
