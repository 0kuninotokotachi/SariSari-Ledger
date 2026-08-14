import 'package:isar/isar.dart';

part 'transaction.g.dart';

enum TransactionType {
  sale,
  utangCredit,
  utangPayment,
}

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)
  late TransactionType type;

  late double amount;

  String? description;

  late DateTime date;

  /// Repayment due date. Only meaningful for [TransactionType.utangCredit].
  DateTime? dueDate;

  /// Links this transaction to a [Customer.id]. Null for walk-in sales
  /// that aren't tied to a customer's utang record.
  int? customerId;
}
