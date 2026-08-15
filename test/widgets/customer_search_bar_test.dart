import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarisari_ledger/widgets/customer_search_bar.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('onChanged fires with typed text', (tester) async {
    String? received;
    await _pump(tester, CustomerSearchBar(onChanged: (v) => received = v));

    await tester.enterText(find.byType(TextField), 'Ana');
    expect(received, 'Ana');
  });

  testWidgets('clear button hidden when empty, shown once text is entered',
      (tester) async {
    await _pump(tester, CustomerSearchBar(onChanged: (_) {}));
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('tapping clear empties the field and calls onChanged with ""',
      (tester) async {
    final received = <String>[];
    await _pump(tester, CustomerSearchBar(onChanged: received.add));

    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(received.last, '');
    expect(find.text('Ana'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('initialQuery pre-fills the field', (tester) async {
    await _pump(
      tester,
      CustomerSearchBar(onChanged: (_) {}, initialQuery: 'Bea'),
    );
    expect(find.text('Bea'), findsOneWidget);
  });
}
