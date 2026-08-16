import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../models/customer.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

/// Connects the UI to the Transaction collection: the ledger of utang
/// loans/repayments (and, eventually, daily sales) behind each customer's
/// running balance.
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
}
