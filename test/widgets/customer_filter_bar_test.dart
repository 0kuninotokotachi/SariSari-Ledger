import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarisari_ledger/providers/customer_provider.dart';
import 'package:sarisari_ledger/widgets/customer_filter_bar.dart';

Future<void> _pump(
  WidgetTester tester, {
  UtangFilter utangFilter = UtangFilter.all,
  CustomerSort sortMode = CustomerSort.nameAsc,
  ValueChanged<UtangFilter>? onFilterChanged,
  ValueChanged<CustomerSort>? onSortChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CustomerFilterBar(
          utangFilter: utangFilter,
          sortMode: sortMode,
          onFilterChanged: onFilterChanged ?? (_) {},
          onSortChanged: onSortChanged ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('marks the active filter chip as selected', (tester) async {
    await _pump(tester, utangFilter: UtangFilter.hasUtang);

    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Has Utang'),
    );
    expect(chip.selected, isTrue);

    final allChip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'All'),
    );
    expect(allChip.selected, isFalse);
  });

  testWidgets('tapping a filter chip calls onFilterChanged with the right value',
      (tester) async {
    UtangFilter? selected;
    await _pump(tester, onFilterChanged: (v) => selected = v);

    await tester.tap(find.widgetWithText(FilterChip, 'Fully Paid'));
    expect(selected, UtangFilter.fullyPaid);
  });

  testWidgets('shows the active sort option in the dropdown', (tester) async {
    await _pump(tester, sortMode: CustomerSort.recentlyAdded);
    expect(find.text('Recently Added'), findsOneWidget);
  });

  testWidgets('choosing a sort option calls onSortChanged with the right value',
      (tester) async {
    CustomerSort? selected;
    await _pump(tester, onSortChanged: (v) => selected = v);

    await tester.tap(find.byType(DropdownButton<CustomerSort>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Balance: High to Low').last);
    await tester.pumpAndSettle();

    expect(selected, CustomerSort.balanceHighToLow);
  });
}
