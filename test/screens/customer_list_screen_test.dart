import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sarisari_ledger/models/customer.dart';
import 'package:sarisari_ledger/providers/customer_provider.dart';
import 'package:sarisari_ledger/providers/transaction_provider.dart';
import 'package:sarisari_ledger/screens/customer_list_screen.dart';
import 'package:sarisari_ledger/widgets/customer_filter_bar.dart';
import 'package:sarisari_ledger/widgets/customer_search_bar.dart';

Customer _customer(int id, String name, {double totalUtang = 0}) {
  return Customer()
    ..id = id
    ..name = name
    ..totalUtang = totalUtang
    ..createdAt = DateTime(2026, 1, 1);
}

Future<CustomerProvider> _pumpList(
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
      child: const MaterialApp(home: CustomerListScreen()),
    ),
  );
  return customerProvider;
}

void main() {
  testWidgets('shows "No customers yet." and hides search/filter when empty',
      (tester) async {
    await _pumpList(tester, []);

    expect(find.text('No customers yet.'), findsOneWidget);
    expect(find.byType(CustomerSearchBar), findsNothing);
    expect(find.byType(CustomerFilterBar), findsNothing);
  });

  testWidgets('renders search bar and filter bar when customers exist',
      (tester) async {
    await _pumpList(tester, [_customer(1, 'Ana')]);

    expect(find.byType(CustomerSearchBar), findsOneWidget);
    expect(find.byType(CustomerFilterBar), findsOneWidget);
  });

  testWidgets('typing in the search bar narrows the rendered list', (tester) async {
    await _pumpList(tester, [_customer(1, 'Ana'), _customer(2, 'Bea')]);

    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();

    // 'Ana' now appears twice: once in the search field, once in the tile.
    expect(find.text('Ana'), findsNWidgets(2));
    expect(find.text('Bea'), findsNothing);
  });

  testWidgets(
      'shows no-results state with a Clear action when filteredCustomers is empty',
      (tester) async {
    await _pumpList(tester, [_customer(1, 'Ana')]);

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pump();

    expect(find.text('No customers match your search or filter.'), findsOneWidget);
    expect(find.text('Clear Search & Filters'), findsOneWidget);
    // Search/filter bars stay visible so the user can adjust them.
    expect(find.byType(CustomerSearchBar), findsOneWidget);
    expect(find.byType(CustomerFilterBar), findsOneWidget);
  });

  testWidgets('tapping "Clear Search & Filters" resets to defaults', (tester) async {
    await _pumpList(tester, [_customer(1, 'Ana'), _customer(2, 'Bea')]);

    await tester.enterText(find.byType(TextField), 'zzz-no-match');
    await tester.pump();
    await tester.tap(find.text('Clear Search & Filters'));
    await tester.pump();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bea'), findsOneWidget);
  });

  testWidgets('tapping a filter chip narrows the list by utang status',
      (tester) async {
    await _pumpList(tester, [
      _customer(1, 'Ana', totalUtang: 100),
      _customer(2, 'Bea', totalUtang: 0),
    ]);

    await tester.tap(find.widgetWithText(FilterChip, 'Has Utang'));
    await tester.pump();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bea'), findsNothing);
  });

  testWidgets("each tile's pin icon reflects the customer's pinned state",
      (tester) async {
    final pinned = _customer(1, 'Ana')..pinOrder = 0;
    final unpinned = _customer(2, 'Bea');
    await _pumpList(tester, [pinned, unpinned]);

    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
  });
}
