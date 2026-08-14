import 'package:isar/isar.dart';

part 'customer.g.dart';

@collection
class Customer {
  Id id = Isar.autoIncrement;

  /// Unique (case-insensitive) so customers can later be merged/looked up
  /// by name without ambiguity.
  @Index(unique: true, caseSensitive: false)
  late String name;

  String? phoneNumber;
  String? address;
  String? facebookId;
  String? email;
  String? notes;

  /// Running utang (credit) balance owed by this customer.
  double totalUtang = 0.0;

  late DateTime createdAt;
}
