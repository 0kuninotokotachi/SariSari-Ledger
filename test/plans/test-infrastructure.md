# Test Infrastructure

Setup notes that the cases in [utang-management.md](utang-management.md)
depend on. Read this before writing the first provider or screen test.

## The core problem: no dependency injection for Isar

`CustomerProvider` and `TransactionProvider` both read `DatabaseService.instance`
directly:

```dart
Isar get _isar => DatabaseService.instance;
```

`DatabaseService.instance` is a `static late final Isar` set by
`DatabaseService.init()`, which `main.dart` calls once at app startup. There
is no seam to inject a fake or mock — any test that exercises a provider
method touching `_isar` needs `DatabaseService.instance` to already hold a
real, open Isar instance with `CustomerSchema` and `TransactionSchema`.

This means "unit" tests for the providers are closer to lightweight
integration tests: they hit a real Isar database on disk (in a temp
directory), not a mock. That's acceptable — Isar is fast and file-based —
but it has consequences for setup/teardown, listed below.

## Required: a shared test helper

Add `test/helpers/isar_test_helper.dart`:

- Opens an Isar instance with `[CustomerSchema, TransactionSchema]` in a
  fresh temp directory (e.g. via `package:path_provider`'s test fallback, or
  `Directory.systemTemp.createTempSync()`), and assigns it to
  `DatabaseService.instance`.
- Exposes a `setUpIsar()` to call from `setUpAll()` and a `tearDownIsar()` to
  call from `tearDownAll()` that closes the instance and deletes the temp
  directory, so tests don't leak files into each other.
- Also exposes a `clearIsar()` to call from `setUp()`, which wipes both
  collections without reopening Isar.

**Note:** `DatabaseService.instance` is `late final`, so it can only be
*assigned* once per test-file isolate — `setUpIsar()` must run once per file
(`setUpAll`), not once per test. Use `clearIsar()` in `setUp()` to reset data
between individual test cases instead; `CustomerProvider.customers` and
utang balances otherwise accumulate state across writes within a file.

## Native binary requirement

Isar needs its native core library loaded. Tests that touch
`DatabaseService.instance` must run via `flutter test` (which handles this
automatically for supported platforms), not `dart test`. If tests run in CI
on a platform without prebuilt Isar binaries, call
`Isar.initializeIsarCore(download: true)` (or equivalent) once in a global
test setup before any test opens an instance.

## Widget test conventions

Follow the existing pattern in `test/widget_test.dart`:

```dart
await tester.pumpWidget(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ChangeNotifierProvider(create: (_) => TransactionProvider()),
    ],
    child: const MaterialApp(home: /* screen under test */),
  ),
);
```

Notes:

- The current `widget_test.dart` HomeScreen case never calls
  `loadCustomers()`, so it only works because `CustomerProvider.customers`
  starts as `[]` — it never touches Isar. Any widget test that needs seeded
  customers/transactions **does** need `DatabaseService.instance` set up
  (via the helper above) and must `await customerProvider.loadCustomers()`
  (and/or seed via `TransactionProvider`) before pumping, then
  `await tester.pumpAndSettle()`.
- Screens that navigate (`Navigator.push`) need `await tester.pumpAndSettle()`
  after the tap to let the route animation finish before asserting on the
  new screen. **Exception: navigating to `CustomerDetailScreen`.** Its
  transaction history shows an indeterminate `CircularProgressIndicator`
  while its `FutureBuilder` is pending, which schedules animation frames
  forever — `pumpAndSettle()` times out. Use bounded pumps instead:
  `await tester.pump(); await tester.pump(const Duration(milliseconds: 300));`
  (enough to process the tap and finish the push transition, without waiting
  for "no more frames").
- **Known unsolved issue (Windows): navigating to `CustomerDetailScreen` in a
  widget test, then letting the test/file end while its transaction-history
  Isar query is still in flight, reliably deadlocks** — observed both with
  bounded pumps and with `tester.runAsync()` attempts to flush the pending
  query, and independent of whether `DatabaseService.instance.close()` is
  called with `deleteFromDisk: true`. The hang shows as zero CPU movement on
  the `flutter_tester`/`dartaotruntime` processes (check via
  `Get-Process | Select ProcessName,Id,CPU` twice, a few seconds apart, on
  Windows) rather than a timeout message, so it's easy to mistake for normal
  slowness. Until root-caused, avoid widget tests that navigate into
  `CustomerDetailScreen`; test its own behavior directly in
  `customer_detail_screen_test.dart` instead (still unwritten as of this
  note), where per-test Isar setup/teardown can be tuned in isolation.
- **The same class of hang reproduces even without navigation, on a screen
  pumped directly** — confirmed while building `SalesScreen`
  (`docs/features/daily-sales-logging.md`), which fires an Isar query from
  `initState()` into a `FutureBuilder`, same shape as
  `CustomerDetailScreen`'s `_transactionsFuture`. Pumping it directly (no
  `Navigator.push`) still left the `FutureBuilder`'s
  `CircularProgressIndicator` showing after `pump()`, a further bounded
  `pump(duration)`, **and** a `pumpAndSettle()` bounded to 5 real seconds —
  the underlying query never completed at all, not just slowly. `tearDownAll`
  (`DatabaseService.instance.close()`) then hung for the full 12-minute test
  timeout. This means the issue isn't specific to navigation transitions or
  to test-teardown timing — it's the general shape of "widget test pumps a
  screen whose `initState` starts an Isar query feeding a `FutureBuilder`"
  that's unsafe here, on any screen, not just `CustomerDetailScreen`. Until
  root-caused, **do not widget-test a screen's Isar-backed `FutureBuilder`
  content at all** — cover that screen's query/aggregation logic at the
  provider level instead (fast, reliable, already proven — see
  `customer_provider_test.dart` and `transaction_provider_test.dart`), and
  verify the screen itself manually via `flutter run`.
- Screens that open a `showDatePicker` dialog need `pumpAndSettle()` after
  tapping the date field, then locate the picker's "OK" button
  (`find.text('OK')` in Material's default date picker) to confirm a date.
- `AddCustomerScreen` and the dialogs in `CustomerDetailScreen` use
  `double.tryParse`/`double.parse` on raw `TextEditingController` text —
  enter amounts via `tester.enterText(find.byType(TextFormField).at(n), '100')`
  rather than relying on default field values.

## Suggested file layout

```
test/
├── TEST_PLAN.md
├── plans/
│   ├── utang-management.md
│   └── test-infrastructure.md
├── helpers/
│   └── isar_test_helper.dart
├── providers/
│   ├── customer_provider_test.dart
│   └── transaction_provider_test.dart
├── screens/
│   ├── home_screen_test.dart
│   ├── add_customer_screen_test.dart
│   ├── customer_list_screen_test.dart
│   └── customer_detail_screen_test.dart
└── widgets/
    ├── customer_tile_test.dart
    ├── transaction_tile_test.dart
    └── utang_summary_card_test.dart
```

`widget_test.dart` at the root can stay as-is or be moved into `screens/` as
`home_screen_test.dart` once it's expanded per the plan.
