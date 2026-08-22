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
`SalesScreen`'s own logic — every case below is already covered at the
provider level in `TransactionProvider`'s section above, which runs fast
and green with no widgets involved.

No automated widget coverage until the underlying issue is root-caused.
Verify manually via `flutter run` instead:

- [ ] Shows "No sales recorded for this day." when the selected day
      (defaults to today) has no sales; total shows `₱0.00`.
- [ ] Adding a sale via the "Add Sale" dialog with a valid amount adds it
      to the day's list and updates the header total.
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

## Known behaviors worth a second opinion

- `salesForDay`/`salesTotalsForMonth` group strictly by the transaction's
  local `DateTime` day — a store that logs sales after midnight local time
  will have them counted on the later day, matching how the "Date Created"
  semantics already work for utang entries.
