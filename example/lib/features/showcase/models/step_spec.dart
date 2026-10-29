import 'package:material_ui/material_ui.dart';

/// Who handles a step of the order. Sets the color and shape of the step icon.
enum StepKind {
  /// The customer.
  customer,

  /// The payment provider.
  payment,

  /// The warehouse.
  warehouse,

  /// The carrier.
  shipping,
}

/// Application data of one step, looked up by node id.
@immutable
class StepSpec {
  /// Creates a step.
  const StepSpec({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.icon,
    required this.facts,
    required this.events,
  });

  /// Title of the card.
  final String title;

  /// Line under the title.
  final String subtitle;

  /// Who handles the step.
  final StepKind kind;

  /// Icon of the step.
  final IconData icon;

  /// Short label and value pairs shown when the step is expanded.
  final List<(String, String)> facts;

  /// Tracking events shown when the step is expanded, as time and text.
  final List<(String, String)> events;
}

/// Application data of one edge. Edges whose ends are not both in the graph are left out.
@immutable
class EdgeSpec {
  /// Creates an edge spec; the id defaults to `from->to`.
  const EdgeSpec(this.from, this.to, {this.label, String? id, this.loop = false, this.labelAt = 0.5})
    : id = id ?? '$from->$to';

  /// Start step.
  final String from;

  /// End step.
  final String to;

  /// Label text, none when `null`.
  final String? label;

  /// Edge id.
  final String id;

  /// Whether the edge closes a cycle, routed over the nodes.
  final bool loop;

  /// Where the label sits along the edge, 0 at the start and 1 at the end.
  final double labelAt;
}

/// A step added on demand, wired in between [after] and [before].
@immutable
class ExtraStep {
  /// Creates an extra step.
  const ExtraStep(this.spec, {required this.after, required this.before});

  /// The step's data.
  final StepSpec spec;

  /// Step the extra step follows.
  final String after;

  /// Step the extra step leads to.
  final String before;
}
