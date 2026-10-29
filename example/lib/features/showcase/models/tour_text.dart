import 'package:flutter/foundation.dart';

/// Title and subtitle of one tour caption.
@immutable
class TourText {
  /// Creates a caption.
  const TourText(this.title, this.body, {this.large = false});

  /// Headline of the caption.
  final String title;

  /// Line under the headline.
  final String body;

  /// Whether the title is set large, for the intro and outro.
  final bool large;

  @override
  bool operator ==(Object other) =>
      other is TourText && other.title == title && other.body == body && other.large == large;

  @override
  int get hashCode => Object.hash(title, body, large);
}
