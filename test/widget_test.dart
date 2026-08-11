import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sarisari_ledger/providers/customer_provider.dart';
import 'package:sarisari_ledger/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows empty state when there are no customers',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CustomerProvider(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('No customers yet.\nTap + to add one.'), findsOneWidget);
    expect(find.text('Add Customer'), findsOneWidget);
  });
}
