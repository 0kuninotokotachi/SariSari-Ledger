import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../models/customer.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

/// Connects the UI to the Transaction collection: the ledger of utang
/// loans/repayments behind each customer's running balance, plus
/// customer-independent daily cash sales.
///
/// Mutating methods here also update the related [Customer.totalUtang] in
/// the same write transaction. Callers must refresh `CustomerProvider`
/// (e.g. `context.read<CustomerProvider>().loadCustomers()`) afterwards so
/// the UI picks up the new balance.
class TransactionProvider extends ChangeNotifier {
  Isar get _isar => DatabaseService.instance;

  Future<List<Transaction>> transactionsForCustomer(Id customerId) {
    return _isar.transactions
        .filter()
        .customerIdEqualTo(customerId)
        .sortByDateDesc()
        .findAll();
  }

  Future<void> addUtangCredit(
    Id customerId, {
    required double amount,
    required DateTime date,
    required DateTime dueDate,
    String? description,
  }) async {
    final transaction = Transaction()
      ..type = TransactionType.utangCredit
      ..amount = amount
      ..description = description
      ..date = date
      ..dueDate = dueDate
      ..customerId = customerId;

    await _isar.writeTxn(() async {
      await _isar.transactions.put(transaction);
      final customer = await _isar.customers.get(customerId);
      if (customer == null) return;
      customer.totalUtang += amount;
      await _isar.customers.put(customer);
    });
    notifyListeners();
  }

  Future<void> addUtangPayment(
    Id customerId, {
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    final transaction = Transaction()
      ..type = TransactionType.utangPayment
      ..amount = amount
      ..description = description
      ..date = date
      ..customerId = customerId;

    await _isar.writeTxn(() async {
      await _isar.transactions.put(transaction);
      final customer = await _isar.customers.get(customerId);
      if (customer == null) return;
      customer.totalUtang -= amount;
      await _isar.customers.put(customer);
    });
    notifyListeners();
  }

  /// Records a cash sale not tied to any customer's utang.
  Future<void> addSale({
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    final transaction = Transaction()
      ..type = TransactionType.sale
      ..amount = amount
      ..description = description
      ..date = date;

    await _isar.writeTxn(() => _isar.transactions.put(transaction));
    notifyListeners();
  }

  /// A single day's sale transactions, newest first.
  Future<List<Transaction>> salesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _isar.transactions
        .filter()
        .typeEqualTo(TransactionType.sale)
        .dateBetween(start, end, includeUpper: false)
        .sortByDateDesc()
        .findAll();
  }

  /// Total sales amount per day (keyed by day, time-of-day stripped) for
  /// the calendar month containing [month]. Used to drive the Daily Sales
  /// calendar's markers.
  Future<Map<DateTime, double>> salesTotalsForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final sales = await _isar.transactions
        .filter()
        .typeEqualTo(TransactionType.sale)
        .dateBetween(start, end, includeUpper: false)
        .findAll();

    final totals = <DateTime, double>{};
    for (final sale in sales) {
      final day = DateTime(sale.date.year, sale.date.month, sale.date.day);
      totals[day] = (totals[day] ?? 0) + sale.amount;
    }
    return totals;
  }
}
