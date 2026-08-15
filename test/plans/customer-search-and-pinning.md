# Test Plan: Customer Search & Pinning

Covers `docs/features/customer-search-and-pinning.md`. Requires the setup
described in [test-infrastructure.md](test-infrastructure.md).

Cases are checkboxes: check one off once a matching test exists and passes.
File references show where each case belongs.

## `CustomerProvider` (`test/providers/customer_provider_test.dart`)

### `pinnedCustomers`
- [ ] Returns pinned customers ordered ascending by `pinOrder`.
- [ ] Returns `[]` when nobody is pinned.

### `filteredCustomers`
- [ ] Default state (`searchQuery: ''`, `UtangFilter.all`,
      `CustomerSort.nameAsc`) returns all customers sorted by name,
      case-insensitively.
- [ ] Search matches `name` case-insensitively as a substring, not just a
      prefix.
- [ ] Search matches `phoneNumber` as a case-insensitive substring.
- [ ] A whitespace-only query behaves like an empty query (matches
      everyone).
- [ ] Leading/trailing whitespace in the query is trimmed before matching.
- [ ] A customer with `phoneNumber == null` doesn't crash the phone-match
      check and is still matchable by name.
- [ ] `UtangFilter.hasUtang` includes only `totalUtang > 0`.
- [ ] `UtangFilter.fullyPaid` includes `totalUtang <= 0` (both exactly zero
      and negative/overpaid) — confirms intentional symmetry with
      `customersWithUtangCount`'s `> 0` threshold.
- [ ] `CustomerSort.balanceHighToLow` / `balanceLowToHigh` order correctly,
      including ties.
- [ ] `CustomerSort.recentlyAdded` orders by `createdAt` descending (newest
      first).
- [ ] Search, filter, and sort compose together correctly (e.g. a query
      that only some `hasUtang` customers match, then sorted by balance).
- [ ] Returns `[]` (no error) when nothing matches.

### `setSearchQuery`/`setUtangFilter`/`setSortMode`
- [ ] Each updates its field and calls `notifyListeners()`, including when
      set to the same value again (confirms current behavior — no dedupe).

### `pinCustomer(customerId)`
- [ ] Sets `pinOrder` to the next available index (appends after existing
      pinned customers).
- [ ] Pinning an already-pinned customer is a no-op (doesn't change its
      `pinOrder`).
- [ ] Throws `PinLimitExceededException(5)` when 5 customers are already
      pinned, and writes nothing.
- [ ] No-ops silently when `customerId` doesn't exist.
- [ ] Calls `loadCustomers()` on success.

### `unpinCustomer(customerId)`
- [ ] Sets `pinOrder` to `null` for the target customer.
- [ ] Compacts remaining pinned customers' `pinOrder` values to stay
      contiguous `0..n-1` after unpinning one from the middle (not just the
      end).
- [ ] No-ops silently when `customerId` doesn't exist or isn't currently
      pinned.
- [ ] Calls `loadCustomers()` afterward.

### `reorderPinnedCustomers(oldIndex, newIndex)`
- [ ] Moving a customer earlier shifts the customers between old and new
      position correctly.
- [ ] Moving a customer later (`newIndex > oldIndex`) correctly accounts
      for `ReorderableListView`'s off-by-one convention (result matches the
      intended final order, not shifted by one).
- [ ] A single pinned customer reordering with itself is a no-op that
      doesn't error.
- [ ] Does not modify any non-pinned customer's data.
- [ ] Calls `loadCustomers()` afterward.

## `CustomerListScreen` (`test/screens/customer_list_screen_test.dart`)

- [ ] Search bar and filter/sort controls render whenever
      `provider.customers` is non-empty.
- [ ] Typing in the search bar calls `setSearchQuery`; the rendered list
      reflects `filteredCustomers`.
- [ ] Tapping each filter chip calls `setUtangFilter` with the matching
      enum value.
- [ ] Changing the sort control calls `setSortMode` with the matching enum
      value.
- [ ] `provider.customers.isEmpty` → shows "No customers yet." and hides
      search/filter controls.
- [ ] `customers` non-empty but `filteredCustomers` empty → shows the
      no-results empty state with a visible "Clear Search & Filters"
      action, and keeps search/filter controls visible.
- [ ] Tapping "Clear Search & Filters" resets query/filter/sort to
      defaults.
- [ ] Each tile's pin icon reflects `customer.pinOrder != null` (filled vs
      outline).
- [ ] Tapping a tile's pin icon calls `pinCustomer` (if unpinned) or
      `unpinCustomer` (if pinned), and does not also trigger row
      navigation.
- [ ] A `PinLimitExceededException` from tapping pin shows a `SnackBar`
      mentioning the limit and doesn't crash.

## `HomeScreen` (`test/screens/home_screen_test.dart`)

- [ ] No pinned header/row rendered when `provider.pinnedCustomers` is
      empty.
- [ ] Renders one `PinnedCustomerCard` per pinned customer, in `pinOrder`
      order, when non-empty.
- [ ] Tapping a pinned card navigates to `CustomerDetailScreen` with the
      correct `customerId`.
- [ ] Dragging to reorder calls `CustomerProvider.reorderPinnedCustomers`
      with the reported indices.
- [ ] The full customer list below is unaffected by pinning (pinned
      customers still appear there too).

## `CustomerDetailScreen` (`test/screens/customer_detail_screen_test.dart`)

- [ ] AppBar pin icon shows outline when unpinned, filled when pinned.
- [ ] Tapping it calls `pinCustomer`/`unpinCustomer` as appropriate and the
      icon updates after reload.
- [ ] `PinLimitExceededException` shows a `SnackBar` and leaves the icon in
      the unpinned state.

## Widgets

### `CustomerTile` (`test/widgets/customer_tile_test.dart`)
- [ ] No pin icon rendered when `showPinButton` is omitted/false
      (regression check — existing layout unaffected).
- [ ] Outline pin icon when `showPinButton: true` and `pinOrder == null`;
      filled when non-null.
- [ ] Tapping the pin icon invokes `onPinToggle`, not `onTap`.

### `PinnedCustomerCard` (`test/widgets/pinned_customer_card_test.dart`)
- [ ] Renders name and formatted balance.
- [ ] Balance color follows the red(>0)/green convention.
- [ ] Long names truncate with ellipsis rather than overflowing the
      fixed-width card.
- [ ] Tapping invokes `onTap`.

### `PinnedCustomersRow` (`test/widgets/pinned_customers_row_test.dart`)
- [ ] Renders one card per customer, in list order.
- [ ] `onReorder` receives the raw `(oldIndex, newIndex)` from
      `ReorderableListView` unmodified (index-adjustment logic lives in the
      provider, not this widget).

### `CustomerSearchBar` (`test/widgets/customer_search_bar_test.dart`)
- [ ] `onChanged` fires with raw typed text on each keystroke.
- [ ] Clear button appears only when text is non-empty; tapping it clears
      the field and calls `onChanged('')`.

### `CustomerFilterBar` (`test/widgets/customer_filter_bar_test.dart`)
- [ ] Marks the currently-active filter chip as selected and the
      currently-active sort option as selected.
- [ ] Tapping a filter chip / choosing a sort option calls the respective
      callback with the right enum value.

## Known behaviors worth a second opinion

- `fullyPaid` treats negative/overpaid balances as "fully paid" (intentional
  — mirrors `customersWithUtangCount`).
- `pinCustomer`/`unpinCustomer` no-op silently on a missing `customerId`
  rather than throwing (mirrors `adjustUtang`/`updateCustomerInfo`).
- Search/filter/sort setters always call `notifyListeners()` even for
  redundant same-value sets — no dedupe, consistent with the rest of the
  provider's simplicity.
