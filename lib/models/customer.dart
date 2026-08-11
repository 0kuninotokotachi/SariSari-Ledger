import 'package:isar/isar.dart';

part 'customer.g.dart';

@collection
class Customer {
  Id id = Isar.autoIncrement;

  late String name;

  String? phoneNumber;

  /// Running utang (credit) balance owed by this customer.
  double totalUtang = 0.0;

  late DateTime createdAt;
}
