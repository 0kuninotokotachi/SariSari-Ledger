import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarisari_ledger/models/customer.dart';
import 'package:sarisari_ledger/widgets/customer_tile.dart';

Customer _customer({double totalUtang = 0, int? pinOrder}) {
  return Customer()
    ..name = 'Ana Reyes'
    ..totalUtang = totalUtang
    ..createdAt = DateTime(2026, 1, 1)
    ..pinOrder = pinOrder;
}

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('renders the customer name and formatted balance', (tester) async {
    await _pump(tester, CustomerTile(customer: _customer(totalUtang: 150)));

    expect(find.text('Ana Reyes'), findsOneWidget);
    expect(find.text('₱150.00'), findsOneWidget);
  });

  testWidgets('tapping invokes onTap', (tester) async {
    var tapped = false;
    await _pump(
      tester,
      CustomerTile(customer: _customer(), onTap: () => tapped = true),
    );

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });

  testWidgets('renders without error when onTap is omitted', (tester) async {
    await _pump(tester, CustomerTile(customer: _customer()));
    expect(find.byType(CustomerTile), findsOneWidget);
  });

  testWidgets('no pin icon rendered when showPinButton is false (default)',
      (tester) async {
    await _pump(tester, CustomerTile(customer: _customer()));
    expect(find.byIcon(Icons.push_pin), findsNothing);
    expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
  });

  testWidgets('shows outline pin icon when unpinned and showPinButton is true',
      (tester) async {
    await _pump(
      tester,
      CustomerTile(customer: _customer(pinOrder: null), showPinButton: true),
    );
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    expect(find.byIcon(Icons.push_pin), findsNothing);
  });

  testWidgets('shows filled pin icon when pinned', (tester) async {
    await _pump(
      tester,
      CustomerTile(customer: _customer(pinOrder: 0), showPinButton: true),
    );
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
  });

  testWidgets('pin icon uses the ambient theme primary color', (tester) async {
    await _pump(
      tester,
      CustomerTile(customer: _customer(pinOrder: 0), showPinButton: true),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.push_pin));
    final colorScheme = Theme.of(tester.element(find.byType(CustomerTile))).colorScheme;
    expect(icon.color, colorScheme.primary);
  });

  testWidgets('tapping the pin icon invokes onPinToggle, not onTap', (tester) async {
    var pinToggled = false;
    var tapped = false;
    await _pump(
      tester,
      CustomerTile(
        customer: _customer(),
        showPinButton: true,
        onPinToggle: () => pinToggled = true,
        onTap: () => tapped = true,
      ),
    );

    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    expect(pinToggled, isTrue);
    expect(tapped, isFalse);
  });
}
