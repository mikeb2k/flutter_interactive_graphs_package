import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';
import 'package:interactive_graphs/src/viewer/layout_transition.dart';
import 'package:interactive_graphs/src/viewer/registries.dart';

void main() {
  group('GraphBounds', () {
    test('positions only, or node boxes with the default size for unsized nodes', () {
      const nodes = [
        GraphNode('A', position: Offset(0, 0), size: Size(20, 10)),
        GraphNode('B', position: Offset(100, 50)),
      ];

      expect(GraphBounds.ofPositions(nodes), const Rect.fromLTRB(0, 0, 100, 50));
      expect(GraphBounds.ofNodes(nodes), const Rect.fromLTRB(-10, -5, 130, 80));
      expect(GraphBounds.ofNodes(const []), Rect.zero);
    });
  });

  group('EdgeHitRegistry', () {
    test('returns the closest edge within tolerance', () {
      final registry = EdgeHitRegistry()
        ..report('near', EdgePathFactory.straight(Offset.zero, const Offset(100, 0), showArrow: false))
        ..report('far', EdgePathFactory.straight(const Offset(0, 10), const Offset(100, 10), showArrow: false));

      expect(registry.hitTest(const Offset(50, 3), 8), 'near');
      expect(registry.hitTest(const Offset(50, 8), 8), 'far');
      expect(registry.hitTest(const Offset(50, 40), 8), isNull);

      registry.retain({'far'});
      expect(registry.hitTest(const Offset(50, 3), 8), 'far');
      registry.clear('far');
      expect(registry.hitTest(const Offset(50, 10), 8), isNull);
    });
  });

  group('AnchorRegistry', () {
    testWidgets('records anchors and notifies once after the frame', (tester) async {
      final registry = AnchorRegistry();
      addTearDown(registry.dispose);
      var notified = 0;
      registry.addListener(() => notified++);

      registry
        ..register('A', 'left', const Offset(0, 10))
        ..register('A', 'right', const Offset(40, 10))
        ..register('A', 'right', const Offset(40, 10));
      expect(registry.offsetOf('A', 'right'), const Offset(40, 10));
      expect(notified, 0);

      await tester.pump();
      expect(notified, 1);

      registry.retain({'B'});
      expect(registry.offsetOf('A', 'left'), isNull);
      await tester.pump();
      expect(notified, 2);
    });
  });

  group('LayoutTransition', () {
    testWidgets('jumps the first time, then springs to new targets', (tester) async {
      final transition = LayoutTransition(const _TestVsync());
      addTearDown(transition.dispose);
      const spring = GraphViewerConfig.defaultLayoutSpring;

      transition.animateTo({'A': Offset.zero}, spring: spring);
      expect(transition.positionOf('A', const {}), Offset.zero);
      expect(transition.isAnimating, isFalse);

      const targets = {'A': Offset(100, 0)};
      transition.animateTo(targets, spring: spring);
      expect(transition.positionOf('A', targets), Offset.zero);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      final midway = transition.positionOf('A', targets).dx;
      expect(midway, greaterThan(0));
      expect(midway, lessThan(100));

      for (var i = 0; i < 200 && transition.isAnimating; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(transition.positionOf('A', targets), targets['A']);
      expect(transition.positionOf('new', const {'new': Offset(5, 5)}), const Offset(5, 5));
    });

    testWidgets('a null spring jumps', (tester) async {
      final transition = LayoutTransition(const _TestVsync());
      addTearDown(transition.dispose);

      transition
        ..animateTo({'A': Offset.zero}, spring: null)
        ..animateTo({'A': const Offset(10, 10)}, spring: null);
      expect(transition.positionOf('A', const {}), const Offset(10, 10));
      expect(transition.isAnimating, isFalse);
    });
  });

  group('painting', () {
    test('dash cuts a path into dashes and gaps', () {
      final line = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      final dashed = EdgePainting.dash(line, 10, 5);

      final metrics = dashed.computeMetrics().toList();
      expect(metrics, hasLength(7));
      expect(metrics.first.length, closeTo(10, 1e-6));
    });

    test('painting every shape and arrow head records drawing commands', () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final paths = <EdgePath>[
        EdgePathFactory.straight(Offset.zero, const Offset(100, 0)),
        EdgePathFactory.curved(Offset.zero, const Offset(100, 0)),
        EdgePathFactory.selfLoop(Offset.zero, const Offset(10, 0)),
        EdgePathFactory.orthogonal(Offset.zero, const Offset(100, 50)),
        EdgePathFactory.rightAngle(Offset.zero, const Offset(100, 50), RightAngleRouting.horizontalFirst),
      ];
      const arrows = [ArrowPainters.triangle, ArrowPainters.open, ArrowPainters.circle, ArrowPainters.none];
      for (final path in paths) {
        for (final arrow in arrows) {
          EdgePainting.paint(canvas, path, EdgeStyle(dashed: path is CurvedEdgePath, arrowPainter: arrow));
        }
      }
      final picture = recorder.endRecording();
      expect(picture.approximateBytesUsed, greaterThan(0));
      picture.dispose();
    });
  });

  group('GraphTheme', () {
    testWidgets('provides its data and falls back to the light defaults', (tester) async {
      const dark = GraphThemeData.dark();
      GraphThemeData? inside;
      GraphThemeData? outside;
      await tester.pumpWidget(
        Column(
          children: [
            Builder(
              builder: (context) {
                outside = GraphTheme.of(context);
                return const SizedBox();
              },
            ),
            GraphTheme(
              data: dark,
              child: Builder(
                builder: (context) {
                  inside = GraphTheme.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      );

      expect(inside, dark);
      expect(outside, const GraphThemeData());
      expect(dark.copyWith(edgeColor: const GraphThemeData().edgeColor).edgeColor, GraphThemeData.defaultEdgeColor);
    });
  });
}

class _TestVsync implements TickerProvider {
  const _TestVsync();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
