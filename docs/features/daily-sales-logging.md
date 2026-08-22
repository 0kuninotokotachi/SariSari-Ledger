# Daily Sales Logging

Recording a day's cash sales and browsing past days via a calendar. Separate
from utang (credit) sales, which continue through the existing "Add Credit"
flow on [Utang Management](utang-management.md)'s `CustomerDetailScreen`.

## Data Model

No new Isar collection or field. Reuses `Transaction`
(`lib/models/transaction.dart`), already documented in
[Utang Management](utang-management.md#data-model): a sale is a
`Transaction` with `type = TransactionType.sale`, `customerId = null`, and
`dueDate = null` — the schema was already shaped for this ("`customerId`
... Null for walk-in sales not tied to a customer's utang"). No
`build_runner` run was needed for this feature.

## Providers

- `TransactionProvider` (`lib/providers/transaction_provider.dart`)
  - `addSale({amount, date, description})` — records a cash sale.
  - `salesForDay(day)` — that day's sale transactions, newest first.
  - `salesTotalsForMonth(month)` — `Map<DateTime, double>` of total sales
    per day (time-of-day stripped) for the calendar month containing
    `month`. Drives `SalesScreen`'s calendar markers.

  All three are plain `Future`-returning methods with no provider-held
  list state, following the same shape as `transactionsForCustomer` —
  callers manage their own local state (see `SalesScreen` below), the same
  way `CustomerDetailScreen` does with `_transactionsFuture`.

## Screens & Navigation

- **`HomeScreen`** — gained a "Daily Sales" nav tile (next to "View
  Customer List") that pushes `SalesScreen`.
- **`SalesScreen`** (`lib/screens/sales_screen.dart`) — a month calendar
  (via the `table_calendar` package) with a marker on days that have
  sales, a selected day's date + total header, that day's sale entries
  below (reusing `TransactionTile`), and a "No sales recorded for this
  day." empty state. A FAB opens an "Add Sale" dialog (amount, date —
  defaulting to the selected day — and an optional note); saving reloads
  both the day's list and the month's calendar totals.

  Per-day totals (`_monthTotals`) are held as plain widget state rather
  than behind a `FutureBuilder`, because `TableCalendar`'s `eventLoader` is
  a synchronous `DateTime -> List<T>` callback and needs the month's data
  already resolved.

  Calendar styling: `daysOfWeekHeight: 28` (the package's 16px default
  clips the dow-label row), a bold, horizontally centered
  (`titleCentered: true`) month/year title, dow labels sized smaller than
  the date-number grid, and Sat/Sun colored red in both the dow row and
  the date grid to read as weekend at a glance.

## Widgets

- `TransactionTile` (`lib/widgets/transaction_tile.dart`) — reused as-is
  from Utang Management, but its color/sign logic was corrected from a
  binary `_isCredit` check to a 3-way switch over `TransactionType` so
  `sale` renders correctly (`+`, a neutral/primary color) instead of
  inheriting `utangPayment`'s green `-` styling. This only affects `sale`
  rows — `CustomerDetailScreen`'s existing `utangCredit`/`utangPayment`
  rendering is unchanged.

## Design Decisions

- **Amount-only entry, no product master.** Matches the app's "ultra
  lightweight, extremely simple UI" requirement and the 30-60 age-group
  target — a store owner taps "Add Sale" and types one number. Per-product
  breakdown was explicitly ruled out; if per-product analytics become a
  real need later, a product master can be layered on without changing
  this screen's core flow.
- **Cash sales only — utang sales stay in the existing "Add Credit" flow.**
  Keeps this feature's provider/screen surface entirely independent of
  `Customer`/utang data (no customer picker, no balance updates here),
  and avoids duplicating the credit-recording UX that already exists on
  `CustomerDetailScreen`.
- **Calendar view, not a flat "today + history list."** Lets an owner
  glance at a month and see which days had sales via the marker, then
  drill into any single day — closer to how a paper sales notebook is
  used than an endless scrolling list would be.
- **`table_calendar` package, not a hand-rolled grid.** `CLAUDE.md` favors
  minimizing external packages, but a correct month calendar (leading/
  trailing days, page swiping, format handling) is enough surface area
  that a maintained, widely-used package was judged worth the one
  dependency, versus hand-maintaining that logic.
