import 'package:interactive_graphs_example/features/showcase/models/step_spec.dart';
import 'package:material_ui/material_ui.dart';

/// The order the showcase plays through: its steps, the steps added on demand and their edges.
abstract final class ShowcaseSteps {
  /// Node id of the first step, which is never removed.
  static const String rootId = 'order';

  /// Steps of the order, in the order the tour adds them.
  static const Map<String, StepSpec> orderSteps = {
    'order': StepSpec(
      title: 'Order placed',
      subtitle: '#4821 · 3 items',
      kind: StepKind.customer,
      icon: Icons.shopping_cart,
      facts: [('Total', '€84.90'), ('Items', '3')],
      events: [('09:02', 'Order received'), ('09:02', 'Confirmation sent')],
    ),
    'payment': StepSpec(
      title: 'Payment',
      subtitle: 'Visa ••42',
      kind: StepKind.payment,
      icon: Icons.credit_card,
      facts: [('Amount', '€84.90'), ('Attempts', '2')],
      events: [('09:03', 'Card declined'), ('09:05', 'Payment approved')],
    ),
    'stock': StepSpec(
      title: 'Stock check',
      subtitle: 'Berlin · BER-1',
      kind: StepKind.warehouse,
      icon: Icons.inventory,
      facts: [('In stock', '3 of 3'), ('Shelf', 'B-14')],
      events: [('09:03', 'Items reserved'), ('09:04', 'Pick list created')],
    ),
    'receipt': StepSpec(
      title: 'Receipt',
      subtitle: 'PDF · Email',
      kind: StepKind.customer,
      icon: Icons.receipt_long,
      facts: [('To', 'anna@mail.de'), ('Format', 'PDF')],
      events: [('09:06', 'Receipt generated'), ('09:06', 'Email delivered')],
    ),
    'pack': StepSpec(
      title: 'Pick & pack',
      subtitle: '2 boxes · 1.8 kg',
      kind: StepKind.warehouse,
      icon: Icons.inventory_2,
      facts: [('Boxes', '2'), ('Weight', '1.8 kg')],
      events: [('10:18', '3 items picked'), ('10:31', 'Labels printed')],
    ),
    'hub': StepSpec(
      title: 'Sorting hub',
      subtitle: 'Leipzig',
      kind: StepKind.shipping,
      icon: Icons.warehouse,
      facts: [('Carrier', 'DHL'), ('Route', 'LE-07')],
      events: [('18:40', 'Arrived at hub'), ('22:15', 'Sorted for delivery')],
    ),
    'notify': StepSpec(
      title: 'SMS updates',
      subtitle: 'ETA 14:00',
      kind: StepKind.customer,
      icon: Icons.sms,
      facts: [('Phone', '•••• 381'), ('Sent', '3')],
      events: [('07:30', 'Arriving today'), ('13:40', 'Driver 5 stops away')],
    ),
    'courier': StepSpec(
      title: 'Out for delivery',
      subtitle: 'Stop 12/40',
      kind: StepKind.shipping,
      icon: Icons.local_shipping,
      facts: [('Driver', 'Mira'), ('Van', 'LE-7341')],
      events: [('14:12', 'Recipient not home'), ('Next day', 'Redelivery scheduled')],
    ),
    'delivered': StepSpec(
      title: 'Delivered',
      subtitle: 'Front door',
      kind: StepKind.customer,
      icon: Icons.home,
      facts: [('Signed', 'A. Weber'), ('Photo', 'Attached')],
      events: [('14:05', 'Handed over'), ('14:06', 'Rating requested')],
    ),
  };

  /// Steps added on demand, in the order the add button uses them.
  static const Map<String, ExtraStep> extraSteps = {
    'gift': ExtraStep(
      StepSpec(
        title: 'Gift wrap',
        subtitle: 'Red · Card',
        kind: StepKind.warehouse,
        icon: Icons.card_giftcard,
        facts: [('Paper', 'Red'), ('Card', 'Included')],
        events: [('10:20', 'Wrapped'), ('10:21', 'Card added')],
      ),
      after: 'pack',
      before: 'hub',
    ),
    'quality': ExtraStep(
      StepSpec(
        title: 'Quality check',
        subtitle: 'Sample 1/3',
        kind: StepKind.warehouse,
        icon: Icons.fact_check,
        facts: [('Checked', '1 of 3'), ('Result', 'Passed')],
        events: [('10:19', 'Sample taken'), ('10:20', 'Passed')],
      ),
      after: 'pack',
      before: 'hub',
    ),
    'insurance': ExtraStep(
      StepSpec(
        title: 'Insurance',
        subtitle: 'Cover €500',
        kind: StepKind.payment,
        icon: Icons.shield,
        facts: [('Cover', '€500'), ('Fee', '€2.40')],
        events: [('10:32', 'Policy issued'), ('10:32', 'Added to parcel')],
      ),
      after: 'pack',
      before: 'hub',
    ),
    'customs': ExtraStep(
      StepSpec(
        title: 'Customs',
        subtitle: 'CN22 · Non-EU',
        kind: StepKind.shipping,
        icon: Icons.public,
        facts: [('Form', 'CN22'), ('Duty', '€0.00')],
        events: [('10:33', 'CN22 filed'), ('16:10', 'Cleared')],
      ),
      after: 'pack',
      before: 'hub',
    ),
  };

  /// Edges of the order. The two packing to hub edges, one per box, fan out, payment retries
  /// itself and a failed delivery goes back to the hub.
  static const List<EdgeSpec> orderEdges = [
    EdgeSpec('order', 'payment'),
    EdgeSpec('order', 'stock'),
    EdgeSpec('payment', 'payment', label: 'retry', loop: true),
    EdgeSpec('payment', 'receipt'),
    EdgeSpec('payment', 'pack', label: 'paid'),
    EdgeSpec('stock', 'pack', label: 'reserved'),
    EdgeSpec('pack', 'hub', label: 'box 1', labelAt: 0.3),
    EdgeSpec('pack', 'hub', label: 'box 2', id: 'pack->hub#2', labelAt: 0.7),
    EdgeSpec('hub', 'notify', label: 'ETA'),
    EdgeSpec('hub', 'courier'),
    EdgeSpec('courier', 'hub', label: 'not home', loop: true),
    EdgeSpec('courier', 'delivered', label: 'signed'),
  ];

  /// Ids of the order steps, in tour order.
  static List<String> get orderIds => orderSteps.keys.toList();

  /// Every step the showcase knows about.
  static final Map<String, StepSpec> allSteps = Map.unmodifiable({
    ...orderSteps,
    for (final MapEntry(:key, :value) in extraSteps.entries) key: value.spec,
  });

  /// Every edge the showcase knows about, by edge id.
  static final Map<String, EdgeSpec> edgeSpecs = Map.unmodifiable({
    for (final spec in [...orderEdges, for (final id in extraSteps.keys) ...extraStepEdges(id)]) spec.id: spec,
  });

  /// Edges of the extra step [stepId].
  static List<EdgeSpec> extraStepEdges(String stepId) {
    final extra = extraSteps[stepId];
    if (extra == null) return const [];
    return [EdgeSpec(extra.after, stepId), EdgeSpec(stepId, extra.before)];
  }

  /// The extra step after [visibleIds], or `null` when all are shown.
  static String? nextExtra(List<String> visibleIds) {
    for (final id in extraSteps.keys) {
      if (!visibleIds.contains(id)) return id;
    }
    return null;
  }

  /// Entrance delay per node, 70 ms apart, so that nodes popping in together are staggered.
  static Map<String, int> staggered(List<String> ids) => {for (final (index, id) in ids.indexed) id: index * 70};
}
