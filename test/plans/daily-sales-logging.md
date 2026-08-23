# Test Plan: Daily Sales Logging

Covers `docs/features/daily-sales-logging.md`. Requires the setup described
in [test-infrastructure.md](test-infrastructure.md). See
[utang-management.md](utang-management.md) for the `TransactionTile`
sale-rendering case and the `HomeScreen` "Daily Sales" tile case — both
touch shared files already owned by that plan.

Cases are checkboxes: check one off once a matching test exists and passes.
File references show where each case belongs.

## `TransactionProvider` (`test/providers/transaction_provider_test.dart`)

### `addSale({amount, date, description})`
- [ ] Inserts a `Transaction` with `type == sale`, `customerId == null`,
      and `dueDate == null`.
- [ ] Leaves `description` `null` when omitted.
- [ ] Calls `notifyListeners()`.

### `salesForDay(day)`
- [ ] Returns only `sale`-type transactions dated on that calendar day
      (time-of-day within the day is included; the next day's midnight is
      excluded).
- [ ] Excludes `utangCredit`/`utangPayment` transactions even if dated the
      same day.
- [ ] Returns them newest-first (`sortByDateDesc`).
- [ ] Returns `[]` for a day with no sales.

### `salesTotalsForMonth(month)`
- [ ] Sums `amount` per day (time-of-day stripped) for every `sale` dated
      within the month containing `month`.
- [ ] Excludes sales dated in the previous/next month (boundary case: the
      1st and the last day of the month are both included; the 1st of the
      *next* month is not).
- [ ] Excludes `utangCredit`/`utangPayment` transactions.
- [ ] Returns `{}` for a month with no sales.

## `WeekdaySalesBarChart` (`test/widgets/weekday_sales_bar_chart_test.dart`)

Pure presentational widget (no Isar/provider dependency — takes a
pre-aggregated `Map<int, double>`), so unlike `SalesScreen` below it's
fully covered by fast widget tests:

- [x] Renders all 7 bars Sun-Sat in order, each with a `₱`-prefixed
      average label and bar height increasing with the average amount;
      the highest average fills the full chart height.
- [x] Sun/Sat weekday labels render in red (`Colors.red.shade400`),
      Mon-Fri in `Colors.black87`.
- [x] A zero-average weekday renders a gray (`Colors.grey.shade300`)
      stub bar with a blank amount label, instead of green.
- [x] An all-zero-average month (the `maxAmount <= 0` guard) renders every
      bar at the minimum stub height with no `NaN`/crash — regression
      case for what dividing by a zero `maxAverage` would otherwise do.
- [x] A weekday missing from the map (not just present-with-zero) also
      falls back to a zero-average stub bar.

## `SalesScreen` (`test/screens/sales_screen_test.dart` — blocked, see below)

**Blocked on the Isar/`FutureBuilder` widget-test hang documented in
[test-infrastructure.md](test-infrastructure.md).** `SalesScreen` fires an
Isar query from `initState()` into a `FutureBuilder`, the same shape as
`CustomerDetailScreen`. Attempting to pump it directly (own
`setUpIsar`/`tearDownIsar`, no navigation) reproduced the same class of
hang already known for `CustomerDetailScreen`, except worse: the query
never completed even after `pump()`, a bounded `pump(duration)`, **and** a
`pumpAndSettle()` bounded to 5 real seconds, and `tearDownAll` then hung
for the full 12-minute test timeout closing Isar. This isn't a bug in
`SalesScreen`'s own logic — every data-shape case below is already
covered at the provider level in `TransactionProvider`'s section above,
which runs fast and green with no widgets involved.
`MonthlySalesSummaryScreen` fires the same kind of Isar query from
`initState()` and is blocked for the same reason; its weekday-averaging
math and its bar rendering are covered separately (by inspection for the
former — it's a short, direct loop — and by `WeekdaySalesBarChart`'s
tests above for the latter).

No automated widget coverage until the underlying issue is root-caused.
Verify manually via `flutter run` instead:

- [ ] Shows "No sales recorded for this day." when the selected day
      (defaults to today) has no sales; total shows `₱0.00` in gray
      (`Colors.grey.shade600`), not green.
- [ ] A day with a nonzero total shows it in green
      (`Colors.green.shade700`).
- [ ] Adding a sale via the "Add Sale" dialog with a valid amount adds it
      to the day's list and updates the header total (turning it green if
      it was previously gray).
- [ ] The "Add Sale" dialog's Save button is inert (dialog stays open)
      when amount is blank, non-numeric, zero, or negative.
- [ ] The "Add Sale" dialog's date field defaults to the currently
      selected day.
- [ ] Selecting a different day in the calendar shows that day's own
      sales/total, independent of the previously selected day's data.
- [ ] A day with a recorded sale shows a calendar marker; a day without
      one does not.
- [ ] The calendar's month/year title is bold and horizontally centered;
      the day-of-week row isn't clipped, and its labels are visibly
      smaller than the date-number grid below.
- [ ] Saturday/Sunday render in a distinct color (red) from weekdays, in
      both the day-of-week row and the date-number grid.
- [ ] The AppBar's "Summary" button (top-right, next to the "Daily Sales"
      title, drawn with a rounded/stadium outline so it reads as a
      button) pushes `MonthlySalesSummaryScreen` for the calendar's
      currently focused month — not necessarily the selected day's month.
- [ ] On `MonthlySalesSummaryScreen`: total sales for the month is green
      when > 0 and gray when exactly `₱0.00`; the prev/next month arrows
      reload both the total and the bar chart for the new month.

## Known behaviors worth a second opinion

- `salesForDay`/`salesTotalsForMonth` group strictly by the transaction's
  local `DateTime` day — a store that logs sales after midnight local time
  will have them counted on the later day, matching how the "Date Created"
  semantics already work for utang entries.
