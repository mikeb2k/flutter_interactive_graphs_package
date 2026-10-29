import 'package:flutter/foundation.dart';

/// Where the camera should go: the whole graph, one node, or a pan from one node to another.
@immutable
class CameraRequest {
  /// Creates a request.
  const CameraRequest({required this.version, this.focusId, this.awaitLayout = true, this.panTo, this.panMillis = 0});

  /// No request yet.
  static const CameraRequest none = CameraRequest(version: 0);

  /// Increases with every request, so that equal moves still count.
  final int version;

  /// Node to center, the whole graph when `null`.
  final String? focusId;

  /// Whether to move only once a pending relayout has settled.
  final bool awaitLayout;

  /// Node to pan to from [focusId].
  final String? panTo;

  /// Duration of the pan.
  final int panMillis;

  @override
  bool operator ==(Object other) =>
      other is CameraRequest &&
      other.version == version &&
      other.focusId == focusId &&
      other.awaitLayout == awaitLayout &&
      other.panTo == panTo &&
      other.panMillis == panMillis;

  @override
  int get hashCode => Object.hash(version, focusId, awaitLayout, panTo, panMillis);
}
