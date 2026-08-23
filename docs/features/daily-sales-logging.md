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

  The "Total: …" header text is green (`Colors.green.shade700`, matching
  `TransactionTile`'s sale/payment color) only when the selected day's
  total is greater than zero; a ₱0.00 day is gray
  (`Colors.grey.shade600`) instead, so an empty day doesn't read as if it
  had a "real" green result.

  The header's built-in format-toggle button (`2 weeks`/`Month`/`Week`)
  never actually changed the calendar — `SalesScreen` doesn't track
  `CalendarFormat` state — so `headerStyle.formatButtonVisible` is set to
  `false` to hide it. In its place, the `Scaffold`'s `AppBar` gets a
  "Summary" action (an `OutlinedButton.icon` with a `StadiumBorder`, so it
  visibly reads as a tappable button rather than plain text) that pushes
  `MonthlySalesSummaryScreen` for the calendar's currently focused month.
  It lives in the AppBar next to the "Daily Sales" title — not inside the
  calendar's own month/year header row — so it stays in a fixed place
  regardless of which month is showing.
- **`MonthlySalesSummaryScreen`**
  (`lib/screens/monthly_sales_summary_screen.dart`) — pushed from
  `SalesScreen`'s "Summary" button, initialized to the calendar's
  currently focused month. Shows that month's total sales (green if > 0,
  gray if zero, same rule as `SalesScreen`'s Total) and a
  `WeekdaySalesBarChart` of **average** sales per day of the week
  (Sun-Sat). It owns independent month state with its own prev/next
  arrows, re-querying `TransactionProvider.salesTotalsForMonth` on every
  month change — it does not share `SalesScreen`'s `_monthTotals`.

  Averages, not sums, so weekdays are comparable regardless of how many
  Mondays vs. Fridays a given month has. For every day in the month
  (whether or not it had a sale) `salesTotalsForMonth`'s per-day amount
  (or 0) is bucketed by `DateTime.weekday` and divided by that weekday's
  occurrence count — a weekday with zero sales all month still counts
  toward the denominator, so it correctly averages down.

## Widgets

- `TransactionTile` (`lib/widgets/transaction_tile.dart`) — reused as-is
  from Utang Management, but its color/sign logic was corrected from a
  binary `_isCredit` check to a 3-way switch over `TransactionType` so
  `sale` renders correctly (`+`, `Colors.green.shade700` — the same green
  `utangPayment` uses, since both represent "good" money) instead of
  inheriting `utangPayment`'s styling by accident. This only affects
  `sale` rows — `CustomerDetailScreen`'s existing
  `utangCredit`/`utangPayment` rendering is unchanged.
- `WeekdaySalesBarChart` (`lib/widgets/weekday_sales_bar_chart.dart`) —
  a hand-rolled (no chart package, per `CLAUDE.md`'s
  minimize-external-packages guidance) pedometer-style bar chart: seven
  bars (Sun-Sat), each a rounded-top `Container` sized relative to the
  week's max value, a `₱`-formatted value label above (blank when the
  average is 0), and a weekday label below colored red for Sat/Sun to
  match `SalesScreen`'s calendar. Takes a pre-aggregated
  `Map<int, double>` (`DateTime.weekday` -> average) — it has no
  provider/query dependency of its own.

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
