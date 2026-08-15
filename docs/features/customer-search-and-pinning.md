# Customer Search & Pinning

Searching, filtering, and sorting the customer list, and pinning favorite
customers to the Home dashboard (modeled on the "pin a chat" pattern in SNS
messaging apps).

## Data Model

### `Customer` (`lib/models/customer.dart`)

One field was added on top of the fields documented in
[Utang Management](utang-management.md):

| Field | Type | Notes |
|---|---|---|
| `pinOrder` | `int?` | Position among pinned customers (`0` = first). `null` means not pinned. Kept contiguous (`0..n-1`) by `CustomerProvider` whenever a customer is unpinned or the pinned row is reordered. Capped at `CustomerProvider.maxPinnedCustomers` (5). |

No `@Index` — the customer list is small and already fully loaded into
memory, so pin/filter/sort logic runs over the in-memory `customers` list
rather than as an Isar-level query, the same way `customersWithUtangCount`
already does.

## Providers

- `CustomerProvider` (`lib/providers/customer_provider.dart`)
  - **Search/filter/sort state**: `searchQuery` (`String`), `utangFilter`
    (`UtangFilter`), `sortMode` (`CustomerSort`), each with a setter
    (`setSearchQuery`/`setUtangFilter`/`setSortMode`) that updates the field
    and calls `notifyListeners()`.
  - `filteredCustomers` — computed getter: `customers` narrowed by
    `searchQuery` (case-insensitive substring match against `name` **and**
    `phoneNumber`) and `utangFilter`, then ordered by `sortMode`.
  - `UtangFilter` — `all`, `hasUtang` (`totalUtang > 0`), `fullyPaid`
    (`totalUtang <= 0`). `hasUtang`/`fullyPaid` are exact complements, so
    every customer falls into exactly one bucket, matching the threshold
    already used by `customersWithUtangCount`.
  - `CustomerSort` — `nameAsc` (default), `balanceHighToLow`,
    `balanceLowToHigh`, `recentlyAdded` (by `createdAt` descending).
  - **Pinning**: `pinnedCustomers` — computed getter, customers with
    `pinOrder != null` sorted ascending by `pinOrder`.
  - `pinCustomer(customerId)` — pins a customer, appending it after the
    currently pinned customers. No-ops if already pinned or the customer
    doesn't exist. Throws `PinLimitExceededException` once
    `maxPinnedCustomers` (5) is reached.
  - `unpinCustomer(customerId)` — unpins a customer and compacts the
    remaining pinned customers' `pinOrder` values back to `0..n-1`.
  - `reorderPinnedCustomers(oldIndex, newIndex)` — reorders the pinned row.
    Takes `ReorderableListView.onReorder`'s raw indices (including its
    "moving later shifts by one" convention) directly — index adjustment
    happens here, not in the widget layer.
  - `PinLimitExceededException` — thrown by `pinCustomer` when the cap is
    already reached; carries the `limit` that was hit.

## Screens & Navigation

No new screens or routes. Existing screens gained:

- **`CustomerListScreen`** — a search bar and a filter/sort bar above the
  list, and a pin toggle on each `CustomerTile`.
- **`HomeScreen`** — a horizontal, drag-to-reorder "Pinned" row between the
  "View Customer List" tile and the "Customers" section, shown only when
  `pinnedCustomers` is non-empty. The full customer list below it is
  unchanged — pinned customers still also appear there.
- **`CustomerDetailScreen`** — a pin/unpin icon in the `AppBar`, next to the
  existing edit-contact-info icon.

## Widgets

- `CustomerTile` (`lib/widgets/customer_tile.dart`) — gained optional
  `showPinButton` (default `false`) and `onPinToggle` params. When enabled,
  renders a leading pin `IconButton` (filled when pinned, outlined when
  not). Existing call sites are unaffected since the params default off.
- `PinnedCustomerCard` (`lib/widgets/pinned_customer_card.dart`) — new,
  fixed-width card for the dashboard's pinned row: name + balance, colored
  red/green like `CustomerTile`.
- `PinnedCustomersRow` (`lib/widgets/pinned_customers_row.dart`) — new,
  wraps `ReorderableListView.builder(scrollDirection: Axis.horizontal)`
  around `PinnedCustomerCard`s. Presentational only — forwards
  `onReorder`'s raw indices to the caller, which wires them to
  `CustomerProvider.reorderPinnedCustomers`.
- `CustomerSearchBar` (`lib/widgets/customer_search_bar.dart`) — new,
  search-by-name-or-phone text field with a clear button.
- `CustomerFilterBar` (`lib/widgets/customer_filter_bar.dart`) — new,
  utang-status filter chips plus a sort selector.

## Design Decisions

- **Pin cap of 5, no auto-eviction.** Mirrors how chat apps cap pinned
  conversations, keeping the dashboard scannable. Pinning a 6th customer
  throws `PinLimitExceededException` rather than silently unpinning the
  oldest — surprising a non-technical user by unpinning something they
  didn't ask to unpin was judged worse than asking them to make room first.
- **Search scope is name + phone number, not Facebook/address/notes/email.**
  `utang-management.md` already notes phone numbers are a contact channel
  store owners recall even though they "change often in this market" and
  aren't the primary identifier. Facebook ID, address, and notes aren't
  things an owner would type into a search box, and including them risks
  confusing matches (e.g. a hit inside free-text `notes`).
- **`fullyPaid` uses `totalUtang <= 0`**, not `== 0`, so it's the exact
  complement of `hasUtang`'s `> 0` and every customer lands in exactly one
  bucket under `All` — consistent with `customersWithUtangCount`'s existing
  threshold, including how it treats an overpaid (negative) balance.
- **Pin toggle lives in two visible, always-on locations** (a leading icon
  on `CustomerTile` within `CustomerListScreen`, and an `AppBar` icon on
  `CustomerDetailScreen`) rather than behind a long-press gesture, since
  discoverability matters more than screen-space economy for this app's
  30-60 age-group users.
