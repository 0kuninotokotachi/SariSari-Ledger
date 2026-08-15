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

/// Thrown by [CustomerProvider.pinCustomer] when the pinned-customer cap
/// ([CustomerProvider.maxPinnedCustomers]) has already been reached.
class PinLimitExceededException implements Exception {
  PinLimitExceededException(this.limit);

  final int limit;
}

enum UtangFilter { all, hasUtang, fullyPaid }

enum CustomerSort { nameAsc, balanceHighToLow, balanceLowToHigh, recentlyAdded }

/// Connects the UI to the Customer collection and keeps [customers]
/// in sync with the underlying Isar store.
class CustomerProvider extends ChangeNotifier {
  List<Customer> customers = [];

  static const int maxPinnedCustomers = 5;

  String searchQuery = '';
  UtangFilter utangFilter = UtangFilter.all;
  CustomerSort sortMode = CustomerSort.nameAsc;

  Isar get _isar => DatabaseService.instance;

  /// Pinned customers, ordered by [Customer.pinOrder] ascending.
  List<Customer> get pinnedCustomers {
    final pinned = customers.where((c) => c.pinOrder != null).toList()
      ..sort((a, b) => a.pinOrder!.compareTo(b.pinOrder!));
    return pinned;
  }

  /// [customers] narrowed by [searchQuery] (matches name or phone number,
  /// case-insensitive) and [utangFilter], then ordered by [sortMode].
  List<Customer> get filteredCustomers {
    final query = searchQuery.trim().toLowerCase();
    final result = customers.where((c) {
      final matchesQuery = query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          (c.phoneNumber?.toLowerCase().contains(query) ?? false);
      final matchesFilter = switch (utangFilter) {
        UtangFilter.all => true,
        UtangFilter.hasUtang => c.totalUtang > 0,
        UtangFilter.fullyPaid => c.totalUtang <= 0,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    switch (sortMode) {
      case CustomerSort.nameAsc:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case CustomerSort.balanceHighToLow:
        result.sort((a, b) => b.totalUtang.compareTo(a.totalUtang));
      case CustomerSort.balanceLowToHigh:
        result.sort((a, b) => a.totalUtang.compareTo(b.totalUtang));
      case CustomerSort.recentlyAdded:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return result;
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void setUtangFilter(UtangFilter filter) {
    utangFilter = filter;
    notifyListeners();
  }

  void setSortMode(CustomerSort mode) {
    sortMode = mode;
    notifyListeners();
  }

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

  Customer? _findById(Id customerId) {
    for (final customer in customers) {
      if (customer.id == customerId) return customer;
    }
    return null;
  }

  /// Pins a customer to the dashboard, appending it after the currently
  /// pinned customers. No-ops if the customer is already pinned or doesn't
  /// exist. Throws [PinLimitExceededException] once [maxPinnedCustomers] is
  /// already reached.
  Future<void> pinCustomer(Id customerId) async {
    final target = _findById(customerId);
    if (target == null || target.pinOrder != null) return;
    if (pinnedCustomers.length >= maxPinnedCustomers) {
      throw PinLimitExceededException(maxPinnedCustomers);
    }
    final nextOrder = pinnedCustomers.length;
    await _isar.writeTxn(() async {
      final customer = await _isar.customers.get(customerId);
      if (customer == null) return;
      customer.pinOrder = nextOrder;
      await _isar.customers.put(customer);
    });
    await loadCustomers();
  }

  /// Unpins a customer and compacts the remaining pinned customers'
  /// [Customer.pinOrder] values back to a contiguous `0..n-1` range.
  /// No-ops if the customer isn't currently pinned or doesn't exist.
  Future<void> unpinCustomer(Id customerId) async {
    final target = _findById(customerId);
    if (target == null || target.pinOrder == null) return;
    final removedOrder = target.pinOrder!;
    final idsToShift = customers
        .where((c) => c.pinOrder != null && c.pinOrder! > removedOrder)
        .map((c) => c.id)
        .toList();

    await _isar.writeTxn(() async {
      final customer = await _isar.customers.get(customerId);
      if (customer == null) return;
      customer.pinOrder = null;
      await _isar.customers.put(customer);
      for (final id in idsToShift) {
        final c = await _isar.customers.get(id);
        if (c == null) continue;
        c.pinOrder = c.pinOrder! - 1;
        await _isar.customers.put(c);
      }
    });
    await loadCustomers();
  }

  /// Reorders the pinned row. [oldIndex]/[newIndex] are passed straight
  /// through from `ReorderableListView.onReorderItem`, whose [newIndex] is
  /// already the target position after the item at [oldIndex] is removed
  /// (no further off-by-one adjustment needed here).
  Future<void> reorderPinnedCustomers(int oldIndex, int newIndex) async {
    final pinned = List<Customer>.from(pinnedCustomers);
    if (oldIndex < 0 || oldIndex >= pinned.length) return;
    final moved = pinned.removeAt(oldIndex);
    pinned.insert(newIndex.clamp(0, pinned.length), moved);

    await _isar.writeTxn(() async {
      for (var i = 0; i < pinned.length; i++) {
        final customer = await _isar.customers.get(pinned[i].id);
        if (customer == null) continue;
        customer.pinOrder = i;
        await _isar.customers.put(customer);
      }
    });
    await loadCustomers();
  }
}
