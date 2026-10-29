import 'package:interactive_graphs_example/features/showcase/models/showcase_copy.dart';

/// State of a step while the order plays out.
enum StepStatus {
  /// Not started yet.
  waiting(ShowcaseCopy.statusWaiting),

  /// Running.
  active(ShowcaseCopy.statusActive),

  /// Running again after a failure.
  retrying(ShowcaseCopy.statusRetrying),

  /// Finished.
  done(ShowcaseCopy.statusDone),

  /// Failed.
  failed(ShowcaseCopy.statusFailed);

  const StepStatus(this.label);

  /// Text shown for the status.
  final String label;

  /// Whether the step is running, first time or retry.
  bool get isRunning => this == StepStatus.active || this == StepStatus.retrying;
}
