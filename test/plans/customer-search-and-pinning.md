# Test Plan: Customer Search & Pinning

Covers `docs/features/customer-search-and-pinning.md`. Requires the setup
described in [test-infrastructure.md](test-infrastructure.md).

Cases are checkboxes: check one off once a matching test exists and passes.
File references show where each case belongs.

## `CustomerProvider` (`test/providers/customer_provider_test.dart`)

### `pinnedCustomers`
- [x] Returns pinned customers ordered ascending by `pinOrder`.
- [x] Returns `[]` when nobody is pinned.

### `filteredCustomers`
- [x] Default state (`searchQuery: ''`, `UtangFilter.all`,
      `CustomerSort.nameAsc`) returns all customers sorted by name,
      case-insensitively.
- [x] Search matches `name` case-insensitively as a substring, not just a
      prefix.
- [x] Search matches `phoneNumber` as a case-insensitive substring.
- [x] A whitespace-only query behaves like an empty query (matches
      everyone).
- [ ] Leading/trailing whitespace in the query is trimmed before matching.
- [x] A customer with `phoneNumber == null` doesn't crash the phone-match
      check and is still matchable by name.
- [x] `UtangFilter.hasUtang` includes only `totalUtang > 0`.
- [x] `UtangFilter.fullyPaid` includes `totalUtang <= 0` (both exactly zero
      and negative/overpaid) — confirms intentional symmetry with
      `customersWithUtangCount`'s `> 0` threshold.
- [x] `CustomerSort.balanceHighToLow` / `balanceLowToHigh` order correctly,
      including ties.
- [x] `CustomerSort.recentlyAdded` orders by `createdAt` descending (newest
      first).
- [x] Search, filter, and sort compose together correctly (e.g. a query
      that only some `hasUtang` customers match, then sorted by balance).
- [x] Returns `[]` (no error) when nothing matches.

### `setSearchQuery`/`setUtangFilter`/`setSortMode`
- [x] Each updates its field and calls `notifyListeners()`, including when
      set to the same value again (confirms current behavior — no dedupe).

### `pinCustomer(customerId)`
- [x] Sets `pinOrder` to the next available index (appends after existing
      pinned customers).
- [x] Pinning an already-pinned customer is a no-op (doesn't change its
      `pinOrder`).
- [x] Throws `PinLimitExceededException(5)` when 5 customers are already
      pinned, and writes nothing.
- [x] No-ops silently when `customerId` doesn't exist.
- [ ] Calls `loadCustomers()` on success.

### `unpinCustomer(customerId)`
- [x] Sets `pinOrder` to `null` for the target customer.
- [x] Compacts remaining pinned customers' `pinOrder` values to stay
      contiguous `0..n-1` after unpinning one from the middle (not just the
      end).
- [x] No-ops silently when `customerId` doesn't exist or isn't currently
      pinned.
- [ ] Calls `loadCustomers()` afterward.

### `reorderPinnedCustomers(oldIndex, newIndex)`
- [x] Moving a customer earlier shifts the customers between old and new
      position correctly.
- [x] Moving a customer later (`newIndex > oldIndex`) inserts it at exactly
      `newIndex` in the resulting list (matches
      `ReorderableListView.onReorderItem`'s "already adjusted" index
      convention — no further off-by-one shift applied).
- [x] A single pinned customer reordering with itself is a no-op that
      doesn't error.
- [x] Does not modify any non-pinned customer's data.
- [ ] Calls `loadCustomers()` afterward.

## `CustomerListScreen` (`test/screens/customer_list_screen_test.dart`)

- [x] Search bar and filter/sort controls render whenever
      `provider.customers` is non-empty.
- [x] Typing in the search bar calls `setSearchQuery`; the rendered list
      reflects `filteredCustomers`.
- [x] Tapping each filter chip calls `setUtangFilter` with the matching
      enum value.
- [ ] Changing the sort control calls `setSortMode` with the matching enum
      value. (`CustomerFilterBar`'s own widget test covers the callback;
      not re-verified wired through this screen.)
- [x] `provider.customers.isEmpty` → shows "No customers yet." and hides
      search/filter controls.
- [x] `customers` non-empty but `filteredCustomers` empty → shows the
      no-results empty state with a visible "Clear Search & Filters"
      action, and keeps search/filter controls visible.
- [x] Tapping "Clear Search & Filters" resets query/filter/sort to
      defaults.
- [x] Each tile's pin icon reflects `customer.pinOrder != null` (filled vs
      outline).
- [ ] Tapping a tile's pin icon calls `pinCustomer` (if unpinned) or
      `unpinCustomer` (if pinned), and does not also trigger row
      navigation. Manually verified live on the emulator (2026-08-16); no
      automated test yet.
- [ ] A `PinLimitExceededException` from tapping pin shows a `SnackBar`
      mentioning the limit and doesn't crash. Manually verified live on
      the emulator (2026-08-16, pinning a 6th customer); no automated test
      yet.

## `HomeScreen` (`test/screens/home_screen_test.dart`)

- [x] No pinned header/row rendered when `provider.pinnedCustomers` is
      empty.
- [x] Renders one `PinnedCustomerCard` per pinned customer, in `pinOrder`
      order, when non-empty.
- [ ] Tapping a pinned card navigates to `CustomerDetailScreen` with the
      correct `customerId`. Intentionally not automated — navigating to
      `CustomerDetailScreen` in a widget test deadlocks on this
      Windows + flutter_test + Isar combination (see comment in
      `home_screen_test.dart`); manually verified live on the emulator.
- [ ] Dragging to reorder calls `CustomerProvider.reorderPinnedCustomers`
      with the reported indices. Manually verified live on the emulator
      (2026-08-16) after switching to `ReorderableDelayedDragStartListener`;
      no automated test yet.
- [x] The full customer list below is unaffected by pinning (pinned
      customers still appear there too).

## `CustomerDetailScreen` (`test/screens/customer_detail_screen_test.dart`)

**No test file exists yet for this screen** — the three cases below are
manually verified live on the emulator (2026-08-16) but have zero
automated coverage. Worth a dedicated follow-up.
- [ ] AppBar pin icon shows outline when unpinned, filled when pinned.
- [ ] Tapping it calls `pinCustomer`/`unpinCustomer` as appropriate and the
      icon updates after reload.
- [ ] `PinLimitExceededException` shows a `SnackBar` and leaves the icon in
      the unpinned state.

## Widgets

### `CustomerTile` (`test/widgets/customer_tile_test.dart`)
- [x] No pin icon rendered when `showPinButton` is omitted/false
      (regression check — existing layout unaffected).
- [x] Outline pin icon when `showPinButton: true` and `pinOrder == null`;
      filled when non-null.
- [x] Tapping the pin icon invokes `onPinToggle`, not `onTap`.

### `PinnedCustomerCard` (`test/widgets/pinned_customer_card_test.dart`)
- [x] Renders name and formatted balance.
- [x] Balance color follows the red(>0)/green convention.
- [x] Long names truncate with ellipsis rather than overflowing the
      fixed-width card.
- [x] Tapping invokes `onTap`.

### `PinnedCustomersRow` (`test/widgets/pinned_customers_row_test.dart`)
- [x] Renders one card per customer, in list order.
- [ ] `onReorder` receives the raw `(oldIndex, newIndex)` from
      `ReorderableListView` unmodified (index-adjustment logic lives in the
      provider, not this widget).

### `CustomerSearchBar` (`test/widgets/customer_search_bar_test.dart`)
- [x] `onChanged` fires with raw typed text on each keystroke.
- [x] Clear button appears only when text is non-empty; tapping it clears
      the field and calls `onChanged('')`.
- [x] Resyncs its displayed text when `initialQuery` changes externally
      (e.g. a "Clear Search & Filters" action resetting
      `CustomerProvider.searchQuery` directly) — regression test added
      2026-08-16 for a bug found during manual QA.

### `CustomerFilterBar` (`test/widgets/customer_filter_bar_test.dart`)
- [x] Marks the currently-active filter chip as selected and the
      currently-active sort option as selected.
- [x] Tapping a filter chip / choosing a sort option calls the respective
      callback with the right enum value.

## Known behaviors worth a second opinion

- `fullyPaid` treats negative/overpaid balances as "fully paid" (intentional
  — mirrors `customersWithUtangCount`).
- `pinCustomer`/`unpinCustomer` no-op silently on a missing `customerId`
  rather than throwing (mirrors `adjustUtang`/`updateCustomerInfo`).
- Search/filter/sort setters always call `notifyListeners()` even for
  redundant same-value sets — no dedupe, consistent with the rest of the
  provider's simplicity.
- `PinnedCustomersRow` uses `ReorderableDelayedDragStartListener` (requires
  a brief press-and-hold before a drag starts), not the immediate
  `ReorderableDragStartListener` — fixed 2026-08-16 after manual QA found
  that a plain horizontal swipe-to-scroll on the pinned row was
  intermittently reordering cards instead of scrolling. This matches what
  `ReorderableListView` itself uses by default on touch platforms.
