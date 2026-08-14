# Test Plan

Index of test plans for SariSari-Ledger. Each plan enumerates the test cases a
feature needs, grouped by layer (`models/` → `providers/` → `screens/` →
`widgets/`, mirroring `lib/`), so writing the actual `*_test.dart` files is a
checklist exercise rather than a design exercise.

These are planning documents, not test code — they live under `test/` (rather
than `docs/`) so they sit next to the suites they describe, but they are
`.md` files and `flutter test` ignores them.

## How to use this plan

1. Pick an unchecked case from a plan below.
2. Write it as a `test`/`testWidgets` case in the matching path (e.g. a case
   from `plans/utang-management.md`'s `CustomerProvider` section goes in
   `test/providers/customer_provider_test.dart`).
2. Check the box in the plan once the test exists and passes.

Update the relevant plan whenever a feature's behavior changes, the same way
`docs/` is kept in sync with `lib/` per `CLAUDE.md`.

## Plans

- [Utang Management](plans/utang-management.md) — customer CRUD, utang
  credit/payment transactions, balance sync, and the Home/List/Detail/Add
  screens. Covers `docs/features/utang-management.md`.
- [Test Infrastructure](plans/test-infrastructure.md) — shared setup needed
  before the above cases can be written (Isar test instances, provider
  wiring, widget test helpers). Read this first if `DatabaseService.instance`
  isn't initialized yet in a test.

Daily Sales Logging has no plan yet — add `plans/daily-sales-logging.md` once
`docs/features/daily-sales-logging.md` exists.

## Test types used in this project

| Type | Tool | What it covers |
|---|---|---|
| Unit | `flutter_test` (`test`) | Provider logic against a real (temp-dir) Isar instance — no widgets. |
| Widget | `flutter_test` (`testWidgets`) | Screens/widgets pumped with `MultiProvider`, asserting on rendered UI and navigation. |

No integration/e2e runner (`integration_test`) or mocking package is set up
yet. Providers talk to `DatabaseService.instance` directly rather than
through an injected interface, so "unit" tests here still hit a real
(temporary, on-disk) Isar database rather than a mock — see
[Test Infrastructure](plans/test-infrastructure.md) for why, and the setup
that makes it manageable.

## Priority order

When picking up work, prefer this order — each layer's tests catch bugs the
layers above it would otherwise mask:

1. **Providers** (`CustomerProvider`, `TransactionProvider`) — the balance
   bookkeeping (`totalUtang` staying in sync with `Transaction` rows) is the
   feature's core correctness property. Bugs here are silent and corrupt
   data the store owner relies on.
2. **Screens** — form validation and navigation. Bugs here are visible but
   don't corrupt data.
3. **Widgets** — presentational; low risk, cheap to test.
