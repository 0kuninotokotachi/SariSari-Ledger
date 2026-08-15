import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sarisari_ledger/models/customer.dart';
import 'package:sarisari_ledger/providers/customer_provider.dart';
import 'package:sarisari_ledger/providers/transaction_provider.dart';
import 'package:sarisari_ledger/screens/home_screen.dart';
import 'package:sarisari_ledger/widgets/pinned_customer_card.dart';
import 'package:sarisari_ledger/widgets/pinned_customers_row.dart';

Customer _customer(int id, String name, {int? pinOrder}) {
  return Customer()
    ..id = id
    ..name = name
    ..createdAt = DateTime(2026, 1, 1)
    ..pinOrder = pinOrder;
}

Future<CustomerProvider> _pumpHome(
  WidgetTester tester,
  List<Customer> customers,
) async {
  final customerProvider = CustomerProvider()..customers = customers;
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  return customerProvider;
}

void main() {
  // Note: navigating to CustomerDetailScreen is intentionally not exercised
  // here. It reads TransactionProvider, which touches a real Isar instance
  // via a FutureBuilder; on this Windows + flutter_test + Isar combination,
  // ending a test (and closing Isar in tearDown) while that query is still
  // in flight reliably deadlocks. Covering that navigation needs dedicated
  // CustomerDetailScreen test infrastructure to resolve, not a quick fix
  // here — tracked as a follow-up rather than blocking this feature's tests.

  testWidgets('no Pinned section rendered when nobody is pinned', (tester) async {
    await _pumpHome(tester, [_customer(1, 'Ana')]);

    expect(find.text('Pinned'), findsNothing);
    expect(find.byType(PinnedCustomersRow), findsNothing);
  });

  testWidgets('renders one PinnedCustomerCard per pinned customer, in pinOrder',
      (tester) async {
    await _pumpHome(tester, [
      _customer(1, 'Ana', pinOrder: 1),
      _customer(2, 'Bea', pinOrder: 0),
      _customer(3, 'Cy'), // not pinned
    ]);

    expect(find.text('Pinned'), findsOneWidget);
    expect(find.byType(PinnedCustomerCard), findsNWidgets(2));
    final row = tester.widget<PinnedCustomersRow>(find.byType(PinnedCustomersRow));
    expect(row.pinnedCustomers.map((c) => c.name).toList(), ['Bea', 'Ana']);
  });

  testWidgets('the full customer list below still shows pinned customers too',
      (tester) async {
    await _pumpHome(tester, [_customer(1, 'Ana', pinOrder: 0)]);

    expect(find.text('Ana'), findsNWidgets(2)); // pinned card + full list tile
  });
}
