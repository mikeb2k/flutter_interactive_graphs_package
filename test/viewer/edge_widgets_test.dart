import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_graphs/interactive_graphs.dart';

void main() {
  Widget host(Widget child) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: SizedBox(width: 400, height: 300, child: child)),
  );

  EdgeDetails details(Offset to) => EdgeDetails(edge: const GraphEdge('A', 'B'), from: Offset.zero, to: to);

  testWidgets('EdgeLine shows its label on long edges only', (tester) async {
    await tester.pumpWidget(host(EdgeLine(details: details(const Offset(200, 0)), label: 'long')));
    expect(find.text('long'), findsOneWidget);

    await tester.pumpWidget(host(EdgeLine(details: details(const Offset(20, 0)), label: 'short')));
    expect(find.text('short'), findsNothing);

    await tester.pumpWidget(host(EdgeLine(details: details(const Offset(200, 0)), label: '  ')));
    expect(find.byType(EdgeLabel), findsNothing);
  });

  testWidgets('EdgeLine uses the label builder', (tester) async {
    await tester.pumpWidget(
      host(
        EdgeLine(
          details: details(const Offset(200, 0)),
          label: 'x',
          labelBuilder: (context, label) => Text('custom $label'),
        ),
      ),
    );
    expect(find.text('custom x'), findsOneWidget);
  });

  testWidgets('EdgeLabelPositioned centers its child on the position and can rotate it', (tester) async {
    const key = ValueKey('label');
    await tester.pumpWidget(
      host(
        const Stack(
          children: [
            EdgeLabelPositioned(
              position: EdgeLabelPosition(Offset(100, 50), 0.3),
              child: SizedBox(key: key, width: 40, height: 20),
            ),
          ],
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(Stack));
    expect(tester.getCenter(find.byKey(key)) - origin, const Offset(100, 50));
    expect(find.byType(Transform), findsNothing);

    await tester.pumpWidget(
      host(
        const Stack(
          children: [
            EdgeLabelPositioned(
              position: EdgeLabelPosition(Offset(100, 50), 0.3),
              rotateWithEdge: true,
              child: SizedBox(key: key, width: 40, height: 20),
            ),
          ],
        ),
      ),
    );
    expect(tester.widget<Transform>(find.byType(Transform)).transform, matrixMoreOrLessEquals(Matrix4.rotationZ(0.3)));
  });
}
