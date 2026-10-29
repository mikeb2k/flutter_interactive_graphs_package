import 'package:interactive_graphs_example/features/stress_test/models/stress_node_data.dart';
import 'package:interactive_graphs_example/features/stress_test/models/stress_node_size.dart';
import 'package:interactive_graphs_example/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// A generated node: a colored, softly shadowed box whose padding, corner radius and text size
/// follow its size class. Kept cheap, since the stress test shows hundreds of them.
class StressNode extends StatelessWidget {
  /// Creates the node.
  const StressNode({super.key, required this.data});

  /// What the node shows.
  final StressNodeData data;

  @override
  Widget build(BuildContext context) {
    final palette = NodePalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: data.colorType.fill(palette),
        borderRadius: _borderRadius,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: _padding,
        child: Text(
          data.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: data.colorType.onFill(palette),
            fontSize: _fontSize,
            fontWeight: FontWeight.w500,
            height: 16 / _fontSize,
          ),
        ),
      ),
    );
  }

  /// Approximates Kuiver's percent corners (50 %, 30 %, 20 % of the node height).
  BorderRadius get _borderRadius => switch (data.size) {
    StressNodeSize.small => BorderRadius.circular(16),
    StressNodeSize.medium => BorderRadius.circular(11),
    StressNodeSize.large => BorderRadius.circular(11),
  };

  EdgeInsets get _padding => switch (data.size) {
    StressNodeSize.small => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    StressNodeSize.medium => const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    StressNodeSize.large => const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  };

  double get _fontSize => switch (data.size) {
    StressNodeSize.small => 11,
    StressNodeSize.medium || StressNodeSize.large => 12,
  };
}
