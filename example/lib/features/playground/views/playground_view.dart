import 'package:material_ui/material_ui.dart';

/// Placeholder until the screen is ported.
class PlaygroundView extends StatelessWidget {
  /// Creates the screen.
  const PlaygroundView({super.key});

  /// Route to this screen.
  static Route<void> route() => MaterialPageRoute<void>(builder: (_) => const PlaygroundView());

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}
