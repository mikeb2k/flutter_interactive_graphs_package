import 'package:material_ui/material_ui.dart';

/// Application data of a playground edge, looked up by edge id.
@immutable
class EdgeData {
  /// Creates edge data.
  const EdgeData({this.label = '', this.labelOffset = 0.5});

  /// Label text, empty for none.
  final String label;

  /// Label position along the edge, `0` at the start and `1` at the end.
  final double labelOffset;

  /// Returns a copy with the given fields replaced.
  EdgeData copyWith({String? label, double? labelOffset}) =>
      EdgeData(label: label ?? this.label, labelOffset: labelOffset ?? this.labelOffset);

  @override
  bool operator ==(Object other) => other is EdgeData && other.label == label && other.labelOffset == labelOffset;

  @override
  int get hashCode => Object.hash(label, labelOffset);
}
