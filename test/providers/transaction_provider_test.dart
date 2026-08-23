import 'package:flutter_test/flutter_test.dart';
import 'package:sarisari_ledger/models/transaction.dart';
import 'package:sarisari_ledger/providers/transaction_provider.dart';

import '../helpers/isar_test_helper.dart';

void main() {
  setUpAll(setUpIsar);
  tearDownAll(tearDownIsar);

  late TransactionProvider provider;

  setUp(() async {
    await clearIsar();
    provider = TransactionProvider();
  });

  group('addSale', () {
    test('inserts a sale transaction with no customer/due date', () async {
      await provider.addSale(
        amount: 150,
        date: DateTime(2026, 3, 5),
        description: 'Rice + eggs',
      );

      final sales = await provider.salesForDay(DateTime(2026, 3, 5));
      expect(sales, hasLength(1));
      expect(sales.first.type, TransactionType.sale);
      expect(sales.first.customerId, isNull);
      expect(sales.first.dueDate, isNull);
      expect(sales.first.amount, 150);
      expect(sales.first.description, 'Rice + eggs');
    });

    test('leaves description null when omitted', () async {
      await provider.addSale(amount: 50, date: DateTime(2026, 3, 5));

      final sales = await provider.salesForDay(DateTime(2026, 3, 5));
      expect(sales.first.description, isNull);
    });

    test('notifies listeners', () async {
      var notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.addSale(amount: 50, date: DateTime(2026, 3, 5));

      expect(notifyCount, 1);
    });
  });

  group('salesForDay', () {
    test('includes only that day\'s sales, newest first', () async {
      await provider.addSale(amount: 100, date: DateTime(2026, 3, 5, 9));
      await provider.addSale(amount: 200, date: DateTime(2026, 3, 5, 18));
      await provider.addSale(amount: 300, date: DateTime(2026, 3, 6));

      final sales = await provider.salesForDay(DateTime(2026, 3, 5));

      expect(sales.map((t) => t.amount).toList(), [200, 100]);
    });

    test('excludes utang transactions dated the same day', () async {
      await provider.addUtangCredit(
        999,
        amount: 999,
        date: DateTime(2026, 3, 5),
        dueDate: DateTime(2026, 4, 5),
      );

      expect(await provider.salesForDay(DateTime(2026, 3, 5)), isEmpty);
    });

    test('returns [] for a day with no sales', () async {
      expect(await provider.salesForDay(DateTime(2026, 3, 5)), isEmpty);
    });
  });

  group('salesTotalsForMonth', () {
    test('sums amounts per day within the month', () async {
      await provider.addSale(amount: 100, date: DateTime(2026, 3, 1));
      await provider.addSale(amount: 50, date: DateTime(2026, 3, 1, 20));
      await provider.addSale(amount: 75, date: DateTime(2026, 3, 31, 23, 59));

      final totals = await provider.salesTotalsForMonth(DateTime(2026, 3, 15));

      expect(totals[DateTime(2026, 3, 1)], 150);
      expect(totals[DateTime(2026, 3, 31)], 75);
    });

    test('excludes sales from the previous and next month', () async {
      await provider.addSale(amount: 999, date: DateTime(2026, 2, 28));
      await provider.addSale(amount: 999, date: DateTime(2026, 4, 1));
      await provider.addSale(amount: 10, date: DateTime(2026, 3, 15));

      final totals = await provider.salesTotalsForMonth(DateTime(2026, 3, 15));

      expect(totals.containsKey(DateTime(2026, 2, 28)), isFalse);
      expect(totals.containsKey(DateTime(2026, 4, 1)), isFalse);
      expect(totals[DateTime(2026, 3, 15)], 10);
    });

    test('excludes utang transactions', () async {
      await provider.addUtangPayment(999, amount: 10, date: DateTime(2026, 3, 10));

      expect(await provider.salesTotalsForMonth(DateTime(2026, 3, 1)), isEmpty);
    });

    test('returns {} for a month with no sales', () async {
      expect(await provider.salesTotalsForMonth(DateTime(2026, 5, 1)), isEmpty);
    });
  });
}
