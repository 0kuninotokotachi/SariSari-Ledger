import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../models/customer.dart';
import '../services/database_service.dart';

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

  Future<void> addCustomer(String name, {String? phoneNumber}) async {
    final customer = Customer()
      ..name = name
      ..phoneNumber = phoneNumber
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() => _isar.customers.put(customer));
    await loadCustomers();
  }

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
