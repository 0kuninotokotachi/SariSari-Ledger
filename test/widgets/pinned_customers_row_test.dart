import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarisari_ledger/models/customer.dart';
import 'package:sarisari_ledger/widgets/pinned_customer_card.dart';
import 'package:sarisari_ledger/widgets/pinned_customers_row.dart';

Customer _customer(int id, String name) {
  return Customer()
    ..id = id
    ..name = name
    ..createdAt = DateTime(2026, 1, 1)
    ..pinOrder = id;
}

void main() {
  testWidgets('renders one card per customer, in list order', (tester) async {
    final customers = [_customer(1, 'Ana'), _customer(2, 'Bea'), _customer(3, 'Cy')];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinnedCustomersRow(
            pinnedCustomers: customers,
            onReorder: (_, _) {},
            onTapCustomer: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(PinnedCustomerCard), findsNWidgets(3));
    expect(
      tester
          .widgetList<PinnedCustomerCard>(find.byType(PinnedCustomerCard))
          .map((c) => c.customer.name)
          .toList(),
      ['Ana', 'Bea', 'Cy'],
    );
  });

  testWidgets('tapping a card invokes onTapCustomer with that customer',
      (tester) async {
    final customers = [_customer(1, 'Ana'), _customer(2, 'Bea')];
    Customer? tapped;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinnedCustomersRow(
            pinnedCustomers: customers,
            onReorder: (_, _) {},
            onTapCustomer: (c) => tapped = c,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Bea'));
    expect(tapped?.name, 'Bea');
  });
}
