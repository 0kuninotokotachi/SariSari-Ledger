import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:sarisari_ledger/models/customer.dart';
import 'package:sarisari_ledger/models/transaction.dart';
import 'package:sarisari_ledger/services/database_service.dart';

Directory? _tempDir;
bool _coreInitialized = false;

/// Opens a fresh, on-disk Isar instance in a temp directory and assigns it
/// to [DatabaseService.instance]. Call once per test file (e.g. from
/// `setUpAll`) — `DatabaseService.instance` is `late final`, so it can only
/// be assigned once per isolate; use [clearIsar] between individual tests
/// instead of reopening.
Future<void> setUpIsar() async {
  // `flutter test` runs on the host desktop platform, which isar_flutter_libs
  // doesn't bundle a prebuilt binary for (unlike the Android/iOS app build).
  // Download the native core once per test run instead.
  if (!_coreInitialized) {
    await Isar.initializeIsarCore(download: true);
    _coreInitialized = true;
  }
  _tempDir = Directory.systemTemp.createTempSync('sarisari_ledger_test_');
  DatabaseService.instance = await Isar.open(
    [CustomerSchema, TransactionSchema],
    directory: _tempDir!.path,
  );
}

/// Wipes all data so each test starts from an empty database, without
/// reopening the Isar instance set up by [setUpIsar]. Call from `setUp`.
Future<void> clearIsar() async {
  final isar = DatabaseService.instance;
  await isar.writeTxn(() async {
    await isar.customers.clear();
    await isar.transactions.clear();
  });
}

/// Closes the Isar instance and deletes its temp directory. Call once per
/// test file (e.g. from `tearDownAll`).
Future<void> tearDownIsar() async {
  // deleteFromDisk: false — deleting the memory-mapped file as part of
  // close() has been observed to hang on Windows when a native query is
  // still in flight (e.g. a widget test that navigated to a screen with a
  // pending FutureBuilder). Deleting the temp directory afterward achieves
  // the same cleanup without that race.
  await DatabaseService.instance.close();
  final dir = _tempDir;
  if (dir != null && dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
  _tempDir = null;
}
