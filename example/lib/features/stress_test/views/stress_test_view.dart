import 'package:material_ui/material_ui.dart';

/// Placeholder until the screen is ported.
class StressTestView extends StatelessWidget {
  /// Creates the screen.
  const StressTestView({super.key});

  /// Route to this screen.
  static Route<void> route() => MaterialPageRoute<void>(builder: (_) => const StressTestView());

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.expand());
}
