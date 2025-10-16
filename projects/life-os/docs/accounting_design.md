# Accounting System Design

## Overview

A double-entry bookkeeping system for Life OS, inspired by GNU Cash but with a cleaner Rails-native implementation.

## Core Principles

1. **Immutability**: Posted transactions are immutable. Corrections are made via reversing entries.
2. **Double-entry enforcement**: Every transaction must balance (sum of debits = sum of credits).
3. **Audit trail**: All changes are tracked via timestamps and status transitions.
4. **Simplicity first**: Start with core features, add complexity only when needed.

## Data Model

### Account

Represents an account in the chart of accounts. Accounts form a hierarchy and have types that determine their normal balance direction.

**Key fields:**
- `code` - Unique account code (e.g., "1000", "1010", "2000")
- `name` - Human-readable name (e.g., "Checking Account", "Salary")
- `account_type` - One of: asset, liability, equity, income, expense
- `parent_id` - Self-referential for account hierarchy (nullable)
- `description` - Optional notes about the account
- `active` - Boolean to soft-delete accounts without breaking history

**Normal balance direction:**
- Assets: Debit increases, Credit decreases
- Expenses: Debit increases, Credit decreases
- Liabilities: Credit increases, Debit decreases
- Equity: Credit increases, Debit decreases
- Income: Credit increases, Debit decreases

### Transaction

Represents a financial transaction (e.g., "Paid rent", "Received salary"). A transaction contains multiple entries that must balance.

**Key fields:**
- `date` - Transaction date (not necessarily when it was created)
- `description` - What this transaction represents
- `status` - One of: draft, posted, void
- `posted_at` - Timestamp when status changed to posted
- `reference` - Optional external reference (check number, invoice number)
- `user_id` - Who created/owns this transaction

**Lifecycle:**
1. `draft` - Being edited, doesn't affect balances
2. `posted` - Finalized, affects balances, immutable
3. `void` - Cancelled, doesn't affect balances, kept for audit trail

### Entry

Represents a single line in a transaction (a debit or credit to an account). Also called a "journal entry" or "posting" in accounting terminology.

**Key fields:**
- `transaction_id` - Which transaction this belongs to
- `account_id` - Which account is being debited or credited
- `amount` - Absolute value of the amount (always positive)
- `entry_type` - Either 'debit' or 'credit'
- `memo` - Optional note for this specific line

**Validation:**
- Amount must be positive (we use entry_type to indicate direction)
- Every transaction must have at least 2 entries
- Sum of debits must equal sum of credits within a transaction

## Design Decisions

### 1. Account Hierarchy: parent_id vs code-based

**Decision**: Use `parent_id` for flexibility.

**Rationale**:
- More Rails-idiomatic with `belongs_to :parent` and `has_many :children`
- Easier to query with ancestry/closure_tree gems if needed later
- Allows renumbering without breaking relationships
- Code field can still exist for display/sorting purposes

### 2. Balance Caching

**Decision**: Calculate on-demand initially, add caching later if needed.

**Rationale**:
- SQLite is fast enough for personal use
- Eliminates cache invalidation complexity
- Always accurate
- Can add `cached_balance` column later with a migration if performance becomes an issue

**Implementation**:
```ruby
def balance
  entries.posted.where(entry_type: 'debit').sum(:amount) -
  entries.posted.where(entry_type: 'credit').sum(:amount)
end

def balance_for_normal_side
  normal_balance_side == 'debit' ? balance : -balance
end
```

### 3. Double-Entry Validation

**Decision**: Multi-layer validation.

**Layers**:
1. Database constraint: `CHECK` constraint on entries table that amount > 0
2. Model validation: Custom validator on Transaction that sums debits and credits
3. Service object: TransactionPoster that validates before changing status to posted

**Rationale**:
- Database constraint is last line of defense
- Model validation gives good user feedback
- Service object enforces business rules (can't post unbalanced transaction)

### 4. Entry Type: Separate columns vs amount sign

**Decision**: Separate `amount` (always positive) and `entry_type` enum.

**Rationale**:
- More explicit and less error-prone
- Easier to validate (amount > 0 is simple check)
- Better for reports (don't need to check sign)
- Matches accounting conventions

Alternative would be positive/negative amounts, but that's more confusing and error-prone.

### 5. Multi-currency Support

**Decision**: Not in initial implementation.

**Rationale**:
- Adds significant complexity (exchange rates, rate changes over time)
- May not be needed for personal use
- Can be added later with a currency_id and exchange_rate fields if needed

### 6. Reconciliation

**Decision**: Add later as a separate feature.

**Rationale**:
- Core double-entry system doesn't require it
- Can be added with a `reconciled_at` timestamp on entries
- Not needed for MVP

## Reports Structure

### Trial Balance
Sum of all posted entries by account, showing debit and credit balances. Should always balance (total debits = total credits).

### Balance Sheet
Assets = Liabilities + Equity
Calculated by summing account balances for each type at a point in time.

### Income Statement (P&L)
Income - Expenses = Net Income
Calculated by summing account balances over a time period.

### Account Ledger
All entries for a specific account, showing running balance.

## API Design (Controllers)

### Accounts
- `GET /accounts` - Chart of accounts (tree view)
- `GET /accounts/:id` - Account detail with ledger
- `POST /accounts` - Create account
- `PATCH /accounts/:id` - Update account (only if no posted entries, or limited fields)

### Transactions
- `GET /transactions` - List transactions
- `GET /transactions/new` - New transaction form
- `POST /transactions` - Create draft transaction
- `GET /transactions/:id/edit` - Edit draft transaction
- `PATCH /transactions/:id` - Update draft transaction
- `DELETE /transactions/:id` - Delete draft transaction
- `POST /transactions/:id/post` - Post transaction (make immutable)
- `POST /transactions/:id/void` - Void posted transaction

### Reports
- `GET /reports/trial_balance`
- `GET /reports/balance_sheet`
- `GET /reports/income_statement`

## Migration Strategy

1. Create accounts table
2. Create transactions table
3. Create entries table with foreign keys
4. Add indexes for common queries
5. Add check constraints for data integrity

## Future Enhancements

- Recurring transactions
- Budget tracking
- Multi-currency support
- Bank statement import
- Reconciliation workflow
- Tags/categories for additional filtering
- Attachments (receipts, invoices)
