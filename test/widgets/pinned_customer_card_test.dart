import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarisari_ledger/models/customer.dart';
import 'package:sarisari_ledger/widgets/pinned_customer_card.dart';

Customer _customer({String name = 'Ana Reyes', double totalUtang = 0}) {
  return Customer()
    ..name = name
    ..totalUtang = totalUtang
    ..createdAt = DateTime(2026, 1, 1);
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

void main() {
  testWidgets('renders name and formatted balance', (tester) async {
    await _pump(tester, PinnedCustomerCard(customer: _customer(totalUtang: 200)));

    expect(find.text('Ana Reyes'), findsOneWidget);
    expect(find.text('₱200.00'), findsOneWidget);
  });

  testWidgets('balance is red when totalUtang > 0', (tester) async {
    await _pump(tester, PinnedCustomerCard(customer: _customer(totalUtang: 50)));
    final text = tester.widget<Text>(find.text('₱50.00'));
    expect(text.style?.color, Colors.red.shade700);
  });

  testWidgets('balance is green when totalUtang <= 0', (tester) async {
    await _pump(tester, PinnedCustomerCard(customer: _customer(totalUtang: 0)));
    final text = tester.widget<Text>(find.text('₱0.00'));
    expect(text.style?.color, Colors.green.shade700);
  });

  testWidgets('long names truncate with ellipsis', (tester) async {
    await _pump(
      tester,
      PinnedCustomerCard(
        customer: _customer(name: 'A Very Long Customer Name That Overflows'),
      ),
    );
    final text = tester.widget<Text>(
      find.text('A Very Long Customer Name That Overflows'),
    );
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('tapping invokes onTap', (tester) async {
    var tapped = false;
    await _pump(
      tester,
      PinnedCustomerCard(customer: _customer(), onTap: () => tapped = true),
    );

    await tester.tap(find.byType(PinnedCustomerCard));
    expect(tapped, isTrue);
  });
}
