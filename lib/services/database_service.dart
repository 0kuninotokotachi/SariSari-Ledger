import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/customer.dart';
import '../models/transaction.dart';

/// Owns the single offline-first Isar instance used across the app.
class DatabaseService {
  DatabaseService._();

  static late final Isar instance;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    instance = await Isar.open(
      [CustomerSchema, TransactionSchema],
      directory: dir.path,
    );
  }
}
