import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarisari_ledger/models/transaction.dart';
import 'package:sarisari_ledger/widgets/transaction_tile.dart';

Future<void> _pump(WidgetTester tester, Transaction transaction) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: TransactionTile(transaction: transaction))),
  );
}

void main() {
  testWidgets('utangCredit renders red, with a + sign and its due date', (tester) async {
    final transaction = Transaction()
      ..type = TransactionType.utangCredit
      ..amount = 150
      ..date = DateTime(2026, 3, 1)
      ..dueDate = DateTime(2026, 4, 1);
    await _pump(tester, transaction);

    expect(find.text('+₱150.00'), findsOneWidget);
    expect(find.textContaining('Due: 2026/04/01'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
    expect(icon.color, Colors.red.shade700);
  });

  testWidgets('utangPayment renders green, with a - sign and no due date',
      (tester) async {
    final transaction = Transaction()
      ..type = TransactionType.utangPayment
      ..amount = 75
      ..date = DateTime(2026, 3, 1);
    await _pump(tester, transaction);

    expect(find.text('-₱75.00'), findsOneWidget);
    expect(find.textContaining('Due:'), findsNothing);
    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_downward));
    expect(icon.color, Colors.green.shade700);
  });

  testWidgets('sale renders green, with a + sign and no due date', (tester) async {
    final transaction = Transaction()
      ..type = TransactionType.sale
      ..amount = 50
      ..date = DateTime(2026, 3, 1);
    await _pump(tester, transaction);

    expect(find.text('+₱50.00'), findsOneWidget);
    expect(find.textContaining('Due:'), findsNothing);
    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
    expect(icon.color, Colors.green.shade700);
  });

  testWidgets('renders the description when present', (tester) async {
    final transaction = Transaction()
      ..type = TransactionType.sale
      ..amount = 50
      ..date = DateTime(2026, 3, 1)
      ..description = 'Rice + eggs';
    await _pump(tester, transaction);

    expect(find.textContaining('Rice + eggs'), findsOneWidget);
  });

  testWidgets('renders without error when description is null', (tester) async {
    final transaction = Transaction()
      ..type = TransactionType.sale
      ..amount = 50
      ..date = DateTime(2026, 3, 1);
    await _pump(tester, transaction);

    expect(find.byType(TransactionTile), findsOneWidget);
  });
}
