# Utang Management

Tracks how much each customer owes the store (utang), and the history of loans and repayments behind that balance.

## Data Model

### `Customer` (`lib/models/customer.dart`)

| Field | Type | Notes |
|---|---|---|
| `id` | `Id` | Isar auto-increment. |
| `name` | `String` | **Unique, case-insensitive** (`@Index(unique: true, caseSensitive: false)`). Enforced so customer names can't collide, in preparation for a future "merge utang across records with the same name" feature. Trimmed before insert. |
| `phoneNumber` | `String?` | Optional. Phone numbers change often in this market, so it is one of several contact channels rather than the primary identifier. |
| `address` | `String?` | Optional. |
| `facebookId` | `String?` | Optional. Facebook is often a more stable contact channel than phone number locally. |
| `email` | `String?` | Optional. |
| `notes` | `String?` | Optional free-text memo for the store owner (e.g. "pays every payday"). |
| `totalUtang` | `double` | Denormalized running balance, kept in sync with `Transaction` writes (see below). |
| `createdAt` | `DateTime` | Set to the date of the *initial* loan when the customer is created (see "Created date" below) — not necessarily "now". |

### `Transaction` (`lib/models/transaction.dart`)

| Field | Type | Notes |
|---|---|---|
| `id` | `Id` | Isar auto-increment. |
| `type` | `TransactionType` | `sale`, `utangCredit` (a loan), or `utangPayment` (a repayment). |
| `amount` | `double` | Always positive; the sign is implied by `type`. |
| `description` | `String?` | Optional free-text note about the transaction. |
| `date` | `DateTime` | When the transaction occurred. |
| `dueDate` | `DateTime?` | Repayment due date. Only set for `utangCredit` transactions — due dates are per-loan, not per-customer, so a customer with multiple outstanding loans can have multiple due dates. |
| `customerId` | `int?` | Links to `Customer.id`. Null for walk-in sales not tied to a customer's utang. |

`Customer.totalUtang` is always updated in the same Isar write transaction as the `Transaction` record that changes it, so the two never drift apart. UI code should never write to `totalUtang` directly — go through `CustomerProvider`/`TransactionProvider`.

### "Created date" semantics

The customer-creation form's required "Date Created" field represents the date the *initial loan* was made, not the date the record was typed into the app. It is written to both `Customer.createdAt` and the initial `Transaction.date`, so a store owner can back-date entries for utang that already existed before they started using the app.

## Providers

- `CustomerProvider` (`lib/providers/customer_provider.dart`)
  - `loadCustomers()` — loads all customers sorted by name.
  - `isNameTaken(name, {excludingId})` — case-insensitive duplicate check via the unique index; used by the add/edit forms.
  - `addCustomerWithInitialUtang(...)` — creates a `Customer` and its opening `utangCredit` `Transaction` atomically. Throws `DuplicateCustomerNameException` on a name collision.
  - `updateCustomerInfo(...)` — edits contact fields (phone, address, Facebook ID, email, notes) from the customer detail screen.
  - `adjustUtang(...)` — internal balance-only helper; not called directly from UI code (see `TransactionProvider`).
- `TransactionProvider` (`lib/providers/transaction_provider.dart`)
  - `transactionsForCustomer(customerId)` — a customer's transactions, newest first.
  - `addUtangCredit(...)` / `addUtangPayment(...)` — record a new loan or repayment and update `Customer.totalUtang` in the same write transaction.
  - Callers must refresh `CustomerProvider` (`loadCustomers()`) afterwards so balance changes are reflected in the UI — the two providers are intentionally decoupled rather than wired together.

## Screens & Navigation

No routing package is used; screens are pushed with `Navigator.push` + `MaterialPageRoute`.

```
Dashboard (HomeScreen)
├── FAB "Add Customer" → AddCustomerScreen
├── "View Customer List" → CustomerListScreen
│                         └── tap a customer → CustomerDetailScreen
└── tap a customer in the dashboard list → CustomerDetailScreen
```

- **`AddCustomerScreen`** (`lib/screens/add_customer_screen.dart`) — required: name, amount, created date (loan date), due date. An "Add Details" toggle reveals optional fields: phone, address, Facebook ID, email, notes, and a transaction memo. Submits via `CustomerProvider.addCustomerWithInitialUtang`; duplicate names surface as an inline field error.
- **`CustomerListScreen`** (`lib/screens/customer_list_screen.dart`) — all customers, name-sorted, each showing their current utang balance (reuses `CustomerTile`). Tapping a row opens `CustomerDetailScreen`.
- **`CustomerDetailScreen`** (`lib/screens/customer_detail_screen.dart`) — current balance, contact info (with an edit dialog), "Record Payment" / "Add Credit" actions, and the full transaction history for that customer.

## Widgets

- `CustomerTile` (`lib/widgets/customer_tile.dart`) — name + balance row; takes an optional `onTap` so it can be reused for both browsing (list/dashboard) and navigation to detail.
- `TransactionTile` (`lib/widgets/transaction_tile.dart`) — a single loan/repayment row, color-coded (loans red, repayments green), showing the due date for loans.
