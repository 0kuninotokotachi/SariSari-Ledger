import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../models/customer.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

/// Thrown when a customer name collides with an existing (case-insensitive)
/// customer name.
class DuplicateCustomerNameException implements Exception {
  DuplicateCustomerNameException(this.name);

  final String name;
}

/// Connects the UI to the Customer collection and keeps [customers]
/// in sync with the underlying Isar store.
class CustomerProvider extends ChangeNotifier {
  List<Customer> customers = [];

  Isar get _isar => DatabaseService.instance;

  double get totalUtang =>
      customers.fold(0.0, (sum, customer) => sum + customer.totalUtang);

  int get customersWithUtangCount =>
      customers.where((customer) => customer.totalUtang > 0).length;

  Future<void> loadCustomers() async {
    customers = await _isar.customers.where().sortByName().findAll();
    notifyListeners();
  }

  /// Case-insensitive duplicate check, used to validate the add/edit forms
  /// before hitting the database's unique index.
  Future<bool> isNameTaken(String name, {Id? excludingId}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final match = await _isar.customers
        .where()
        .nameEqualTo(trimmed)
        .findFirst();
    if (match == null) return false;
    return match.id != excludingId;
  }

  /// Creates a new customer together with the initial utang loan that
  /// prompted the record, as a single transaction so the ledger always has
  /// a matching [Transaction] entry for the customer's opening balance.
  Future<Customer> addCustomerWithInitialUtang({
    required String name,
    required double amount,
    required DateTime loanDate,
    required DateTime dueDate,
    String? phoneNumber,
    String? address,
    String? facebookId,
    String? email,
    String? notes,
    String? description,
  }) async {
    final trimmedName = name.trim();
    if (await isNameTaken(trimmedName)) {
      throw DuplicateCustomerNameException(trimmedName);
    }

    final customer = Customer()
      ..name = trimmedName
      ..phoneNumber = phoneNumber
      ..address = address
      ..facebookId = facebookId
      ..email = email
      ..notes = notes
      ..totalUtang = amount
      ..createdAt = loanDate;

    final loan = Transaction()
      ..type = TransactionType.utangCredit
      ..amount = amount
      ..description = description
      ..date = loanDate
      ..dueDate = dueDate;

    try {
      await _isar.writeTxn(() async {
        final customerId = await _isar.customers.put(customer);
        loan.customerId = customerId;
        await _isar.transactions.put(loan);
      });
    } on IsarError {
      throw DuplicateCustomerNameException(trimmedName);
    }

    await loadCustomers();
    return customer;
  }

  Future<void> updateCustomerInfo(
    Id customerId, {
    String? phoneNumber,
    String? address,
    String? facebookId,
    String? email,
    String? notes,
  }) async {
    await _isar.writeTxn(() async {
      final customer = await _isar.customers.get(customerId);
      if (customer == null) return;
      customer.phoneNumber = phoneNumber;
      customer.address = address;
      customer.facebookId = facebookId;
      customer.email = email;
      customer.notes = notes;
      await _isar.customers.put(customer);
    });
    await loadCustomers();
  }

  /// Applies a raw balance delta to a customer's running utang total.
  /// Internal helper — callers that create a matching [Transaction] record
  /// (see [TransactionProvider]) should use this instead of writing to
  /// [Customer.totalUtang] directly, so the two stay in sync.
  Future<void> adjustUtang(Id customerId, double delta) async {
    await _isar.writeTxn(() async {
      final customer = await _isar.customers.get(customerId);
      if (customer == null) return;
      customer.totalUtang += delta;
      await _isar.customers.put(customer);
    });
    await loadCustomers();
  }

  Future<void> deleteCustomer(Id customerId) async {
    await _isar.writeTxn(() => _isar.customers.delete(customerId));
    await loadCustomers();
  }
}
