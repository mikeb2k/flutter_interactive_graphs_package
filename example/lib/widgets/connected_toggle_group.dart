import 'package:material_ui/material_ui.dart';

/// A row of connected toggle buttons with exactly one selected, e.g. to pick a layout.
class ConnectedToggleGroup<T extends Object> extends StatelessWidget {
  /// Creates the group.
  const ConnectedToggleGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelect,
    this.icon,
  });

  /// The choices, in display order.
  final List<T> options;

  /// The selected choice.
  final T selected;

  /// Text of a choice.
  final String Function(T option) label;

  /// Optional icon of a choice.
  final IconData Function(T option)? icon;

  /// Called with the chosen option.
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: [for (final option in options) _segment(option)],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: _onChanged,
    );
  }

  ButtonSegment<T> _segment(T option) {
    final iconOf = icon;
    return ButtonSegment<T>(
      value: option,
      label: Text(label(option)),
      icon: iconOf == null ? null : Icon(iconOf(option), size: 18),
    );
  }

  void _onChanged(Set<T> selection) {
    if (selection.isNotEmpty) onSelect(selection.first);
  }
}
