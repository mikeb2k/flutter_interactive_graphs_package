import 'package:material_ui/material_ui.dart';

/// Icon button of the screen toolbars, with a tooltip that doubles as its semantic label.
class ToolbarButton extends StatelessWidget {
  /// Creates a toolbar button.
  const ToolbarButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  /// The icon.
  final IconData icon;

  /// Tooltip and accessibility label.
  final String tooltip;

  /// Called on tap; `null` disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
}
