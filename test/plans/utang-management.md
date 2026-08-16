# Test Plan: Utang Management

Covers `docs/features/utang-management.md`. Requires the setup described in
[test-infrastructure.md](test-infrastructure.md).

Cases are checkboxes: check one off once a matching test exists and passes.
File references show where each case belongs.

## `CustomerProvider` (`test/providers/customer_provider_test.dart`)

### `loadCustomers()`
- [ ] Populates `customers` sorted by name, ascending.
- [ ] Leaves `customers` as `[]` when the database is empty.
- [ ] Calls `notifyListeners()` (assert via a listener callback count).

### `isNameTaken(name, {excludingId})`
- [ ] Returns `false` when no customer has that name.
- [ ] Returns `true` for an exact (case-sensitive) match.
- [ ] Returns `true` for a case-insensitive match (`"JUAN"` vs stored `"juan"`).
- [ ] Returns `false` when `name.trim()` is empty (e.g. `""` or `"   "`),
      without querying the database.
- [ ] Trims surrounding whitespace before comparing (`" Juan "` matches
      stored `"Juan"`).
- [ ] Returns `false` when the only match is `excludingId` itself (editing a
      customer without renaming them shouldn't flag their own name as taken).
- [ ] Returns `true` when a match exists with an id other than `excludingId`.

### `addCustomerWithInitialUtang(...)`
- [ ] Creates a `Customer` row with `totalUtang == amount` and
      `createdAt == loanDate` (not `DateTime.now()`).
- [ ] Creates exactly one `Transaction` row with
      `type == TransactionType.utangCredit`, `amount == amount`,
      `date == loanDate`, `dueDate == dueDate`, and `customerId` pointing at
      the new customer.
- [ ] Trims the name before saving (`" Juan "` → stored as `"Juan"`).
- [ ] Leaves optional fields (`phoneNumber`, `address`, `facebookId`,
      `email`, `notes`) `null` when omitted.
- [ ] Leaves the transaction's `description` `null` when omitted.
- [ ] Throws `DuplicateCustomerNameException` (and writes nothing) when the
      name already exists, case-insensitively.
- [ ] `DuplicateCustomerNameException.name` carries the *trimmed* name that
      was attempted.
- [ ] Customer and transaction are written atomically: if the write fails
      partway (simulate by triggering the unique-index `IsarError` path),
      no orphaned `Customer` or `Transaction` row is left behind.
- [ ] Calls `loadCustomers()` on success, so `customers` reflects the new
      row without a manual reload.
- [ ] Returns the created `Customer` with its assigned `id` populated.

### `updateCustomerInfo(...)`
- [ ] Updates `phoneNumber`, `address`, `facebookId`, `email`, `notes` and
      leaves `name`, `totalUtang`, `createdAt` unchanged.
- [ ] Passing `null` for a previously-set field clears it (sets it back to
      `null`), since the method assigns unconditionally.
- [ ] No-ops silently (no throw) when `customerId` doesn't exist.
- [ ] Calls `loadCustomers()` so `customers` reflects the update.

### `adjustUtang(customerId, delta)`
- [ ] Positive `delta` increases `totalUtang` by that amount.
- [ ] Negative `delta` decreases `totalUtang` by that amount (can go
      negative — no clamping to zero; confirm this is intentional or file a
      follow-up if not).
- [ ] No-ops silently when `customerId` doesn't exist.
- [ ] Calls `loadCustomers()` afterward.

### `deleteCustomer(customerId)`
- [ ] Removes the customer row.
- [ ] Does **not** remove that customer's `Transaction` rows (confirms
      current behavior — orphaned transactions with a dangling
      `customerId`). Flag as a candidate follow-up if unintended.
- [ ] Calls `loadCustomers()` so `customers` no longer includes it.

### Computed getters
- [ ] `totalUtang` sums every customer's `totalUtang`; returns `0.0` when
      `customers` is empty.
- [ ] `totalUtang` includes customers with a zero or negative balance (no
      filtering).
- [ ] `customersWithUtangCount` counts only customers with
      `totalUtang > 0` — a customer at exactly `0` or negative (overpaid) is
      **not** counted.

## `TransactionProvider` (`test/providers/transaction_provider_test.dart`)

### `transactionsForCustomer(customerId)`
- [ ] Returns only transactions whose `customerId` matches, excluding other
      customers' transactions.
- [ ] Returns them newest-first (`sortByDateDesc`).
- [ ] Returns `[]` for a customer with no transactions.

### `addUtangCredit(...)`
- [ ] Inserts a `Transaction` with `type == utangCredit` and the given
      `dueDate`.
- [ ] Increments the customer's `totalUtang` by `amount`, in the same write
      transaction (verify both the `Transaction` row and the updated
      `Customer.totalUtang` after the call).
- [ ] Leaves `description` `null` when omitted.
- [ ] When `customerId` doesn't match any customer, the transaction is
      still written (no balance to update) — confirms current behavior of
      creating an orphaned credit record; flag as a candidate follow-up if
      unintended.
- [ ] Calls `notifyListeners()`.

### `addUtangPayment(...)`
- [ ] Inserts a `Transaction` with `type == utangPayment` and `dueDate ==
      null`.
- [ ] Decrements the customer's `totalUtang` by `amount`.
- [ ] A payment larger than the current balance drives `totalUtang`
      negative (no clamp to zero) — confirms current behavior; note whether
      the UI should prevent this (see `CustomerDetailScreen` cases below).
- [ ] Calls `notifyListeners()`.

### Cross-provider sync (documented as intentionally decoupled)
- [ ] After `addUtangCredit`/`addUtangPayment`, `CustomerProvider.customers`
      is **not** automatically updated — the caller must call
      `CustomerProvider.loadCustomers()` separately. Write one test that
      asserts this decoupling explicitly, so a future refactor that
      accidentally couples (or accidentally forgets to couple at the call
      site) is caught either way.

## `AddCustomerScreen` (`test/screens/add_customer_screen_test.dart`)

- [ ] Shows "Please enter a name" under the Name field on submit when name
      is empty/whitespace-only, and does not call the provider.
- [ ] Shows "Please enter a valid amount" when amount is empty,
      non-numeric, zero, or negative.
- [ ] Shows a snackbar "Please select a due date" when due date hasn't been
      picked, even if name/amount are valid.
- [ ] Picking a loan date and due date via the date fields updates the
      displayed text (`yyyy/MM/dd` format).
- [ ] Successful submit calls
      `CustomerProvider.addCustomerWithInitialUtang` with the entered
      values and pops the screen.
- [ ] Duplicate-name submit shows "This name is already registered" inline
      under the Name field, does **not** pop the screen, and re-enables the
      Save button (stops the loading spinner).
- [ ] Editing the Name field after a duplicate-name error clears the inline
      error (`onChanged` behavior).
- [ ] "Add Details" toggle off by default; toggling it on reveals phone,
      address, Facebook ID, email, notes, and loan description fields;
      toggling off hides them again.
- [ ] Optional fields left blank are passed as `null` (via `_emptyToNull`),
      not empty strings.
- [ ] Save button shows a spinner and becomes non-interactive while a save
      is in flight (rapid double-tap doesn't double-submit).
- [ ] A generic save failure (non-duplicate exception) shows "Failed to
      save. Please try again." via snackbar and re-enables the form.

## `CustomerListScreen` (`test/screens/customer_list_screen_test.dart`)

- [ ] Shows "No customers yet." when the provider's `customers` is empty.
- [ ] Renders one `CustomerTile` per customer with a `Divider` between rows.
- [ ] Tapping a row navigates to `CustomerDetailScreen` with that
      customer's `id`.

## `CustomerDetailScreen` (`test/screens/customer_detail_screen_test.dart`)

- [ ] Shows "Customer not found." when `customerId` doesn't match any
      customer in the provider (e.g. deleted elsewhere).
- [ ] Displays the current balance formatted as `₱#,##0.00`
      (`_formattedUtang`), red when `totalUtang > 0`, green otherwise
      (including negative/overpaid).
- [ ] Shows "No contact info yet..." placeholder when all of phone,
      address, Facebook ID, email, notes are `null`/empty.
- [ ] Renders one row per non-empty contact field, in the fixed order:
      phone, address, Facebook, email, notes.
- [ ] AppBar title shows the customer's name.
- [ ] Edit-contact-info dialog pre-fills each field with the customer's
      current value.
- [ ] Canceling the edit dialog leaves the customer's data unchanged.
- [ ] Saving the edit dialog calls
      `CustomerProvider.updateCustomerInfo` with trimmed/`null`-ified
      values and refreshes the displayed contact info.
- [ ] "Record Payment" dialog's Save button is inert (dialog stays open)
      when amount is blank, non-numeric, zero, or negative.
- [ ] "Add Credit" dialog's Save button is inert when a due date hasn't
      been picked, even with a valid amount.
- [ ] "Record Payment" dialog does not require/show a due date field
      (`isCredit == false` branch).
- [ ] Confirming "Record Payment" calls
      `TransactionProvider.addUtangPayment`, then reloads both the balance
      and the transaction list.
- [ ] Confirming "Add Credit" calls `TransactionProvider.addUtangCredit`,
      then reloads both the balance and the transaction list.
- [ ] Transaction history shows "No transactions yet." when empty.
- [ ] Transaction history renders newest-first, matching
      `transactionsForCustomer` ordering.
- [ ] Pull-to-refresh (`RefreshIndicator`) re-triggers both
      `CustomerProvider.loadCustomers()` and the transactions future.

## `HomeScreen` (`test/screens/home_screen_test.dart` — supersedes root `widget_test.dart`)

- [ ] Empty state: shows "No customers yet.\nTap + to add one." plus the
      summary card and "View Customer List" tile (existing case in
      `widget_test.dart` — migrate here).
- [ ] Non-empty state: renders `UtangSummaryCard` with the provider's
      `totalUtang`, `customers.length`, and `customersWithUtangCount`.
- [ ] Non-empty state: renders one `CustomerTile` per customer below the
      "Customers" header, in provider order (name-sorted).
- [ ] Tapping a customer row navigates to `CustomerDetailScreen` with the
      correct `customerId`.
- [ ] Tapping "View Customer List" navigates to `CustomerListScreen`.
- [ ] Tapping the FAB ("Add Customer") navigates to `AddCustomerScreen`.

## Widgets

### `CustomerTile` (`test/widgets/customer_tile_test.dart`)
- [ ] Renders the customer's name and formatted balance.
- [ ] Tapping invokes the provided `onTap` callback.
- [ ] Renders without error when `onTap` is omitted (browsing-only reuse,
      per `docs/features/utang-management.md`).

### `TransactionTile` (`test/widgets/transaction_tile_test.dart`)
- [ ] `utangCredit` transactions render in red and show the due date.
- [ ] `utangPayment` transactions render in green and do **not** show a due
      date (since `dueDate` is always `null` for payments).
- [ ] Renders the transaction's `description` when present, and degrades
      gracefully (no crash / sensible fallback) when `null`.

### `UtangSummaryCard` (`test/widgets/utang_summary_card_test.dart`)
- [ ] Formats `totalUtang` as Philippine peso with 2 decimal places.
- [ ] Displays `customerCount` and `customersWithUtang` correctly,
      including the `0`/`0` case.

## Known behaviors worth a second opinion

These are cases above marked "confirms current behavior" — write the test
to lock in what the code does today, but flag them to the feature owner
since they may be unintentional:

- Overpayment: `addUtangPayment` lets `totalUtang` go negative with no
  warning in the UI.
- `deleteCustomer` doesn't cascade-delete that customer's `Transaction`
  rows, leaving orphans with a dangling `customerId`.
- `addUtangCredit`/`addUtangPayment` against a non-existent `customerId`
  silently writes an orphaned transaction instead of throwing.
