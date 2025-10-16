# Accounting System Examples

This document shows practical examples of using the accounting system.

## Setting Up Accounts

```ruby
# Create asset accounts
checking = Account.create!(
  code: "1000",
  name: "Checking Account",
  account_type: "asset"
)

savings = Account.create!(
  code: "1010",
  name: "Savings Account",
  account_type: "asset"
)

# Create expense accounts
rent = Account.create!(
  code: "5000",
  name: "Rent Expense",
  account_type: "expense"
)

groceries = Account.create!(
  code: "5010",
  name: "Groceries",
  account_type: "expense"
)

# Create income accounts
salary = Account.create!(
  code: "4000",
  name: "Salary Income",
  account_type: "income"
)

# Create liability accounts
credit_card = Account.create!(
  code: "2000",
  name: "Credit Card",
  account_type: "liability"
)
```

## Creating a Simple Transaction

Example: Receiving salary of $5,000

```ruby
user = Current.user

transaction = Transaction.create!(
  user: user,
  date: Date.current,
  description: "October salary",
  status: "draft"
)

# Debit (increase) the checking account
transaction.entries.create!(
  account: checking,
  amount: 5000.00,
  entry_type: "debit",
  memo: "Salary deposit"
)

# Credit (increase) the salary income account
transaction.entries.create!(
  account: salary,
  amount: 5000.00,
  entry_type: "credit",
  memo: "October salary"
)

# Post the transaction
transaction.post! if transaction.valid_for_posting?
```

## Recording an Expense

Example: Paying $1,200 rent with check #1234

```ruby
transaction = Transaction.create!(
  user: user,
  date: Date.current,
  description: "October rent payment",
  reference: "Check #1234",
  status: "draft"
)

# Credit (decrease) the checking account
transaction.entries.create!(
  account: checking,
  amount: 1200.00,
  entry_type: "credit",
  memo: "Rent payment via check"
)

# Debit (increase) the rent expense account
transaction.entries.create!(
  account: rent,
  amount: 1200.00,
  entry_type: "debit",
  memo: "October rent"
)

transaction.post!
```

## Recording a Credit Card Purchase

Example: Buying $150 of groceries on credit card

```ruby
transaction = Transaction.create!(
  user: user,
  date: Date.current,
  description: "Grocery shopping at Whole Foods",
  status: "draft"
)

# Debit (increase) the groceries expense
transaction.entries.create!(
  account: groceries,
  amount: 150.00,
  entry_type: "debit",
  memo: "Weekly groceries"
)

# Credit (increase) the credit card liability
transaction.entries.create!(
  account: credit_card,
  amount: 150.00,
  entry_type: "credit",
  memo: "Charged to Visa"
)

transaction.post!
```

## Paying Off Credit Card

Example: Paying $500 toward credit card from checking

```ruby
transaction = Transaction.create!(
  user: user,
  date: Date.current,
  description: "Credit card payment",
  status: "draft"
)

# Credit (decrease) checking account
transaction.entries.create!(
  account: checking,
  amount: 500.00,
  entry_type: "credit",
  memo: "Payment to Visa"
)

# Debit (decrease) credit card liability
transaction.entries.create!(
  account: credit_card,
  amount: 500.00,
  entry_type: "debit",
  memo: "Payment received"
)

transaction.post!
```

## Split Transaction

Example: ATM withdrawal of $200 for groceries and entertainment

```ruby
entertainment = Account.find_by!(code: "5020") # assume this exists

transaction = Transaction.create!(
  user: user,
  date: Date.current,
  description: "ATM withdrawal - mixed expenses",
  status: "draft"
)

# Credit (decrease) checking account for total withdrawal
transaction.entries.create!(
  account: checking,
  amount: 200.00,
  entry_type: "credit",
  memo: "ATM withdrawal"
)

# Debit (increase) groceries expense for part of it
transaction.entries.create!(
  account: groceries,
  amount: 120.00,
  entry_type: "debit",
  memo: "Food shopping"
)

# Debit (increase) entertainment expense for the rest
transaction.entries.create!(
  account: entertainment,
  amount: 80.00,
  entry_type: "debit",
  memo: "Movie tickets and dinner"
)

transaction.post!
```

## Correcting a Mistake

Example: Posted transaction has wrong amount, need to reverse and recreate

```ruby
# Find the incorrect transaction
wrong_transaction = Transaction.find(123)

# Create a reversing transaction
reversal = wrong_transaction.create_reversing_transaction(description_suffix: "CORRECTION")
reversal.save!
reversal.post!

# Now create the correct transaction
correct_transaction = Transaction.create!(
  user: user,
  date: wrong_transaction.date,
  description: "#{wrong_transaction.description} [CORRECTED]",
  status: "draft"
)

# Add the correct entries...
correct_transaction.entries.create!(...)
correct_transaction.post!
```

## Querying Account Balances

```ruby
# Get current balance
checking.balance
# => 3450.00 (positive for asset account means you have money)

# Get balance as of specific date
checking.balance(as_of_date: Date.new(2024, 9, 30))
# => 3200.00

# Get balance with normal side adjustment
checking.normal_balance
# => 3450.00 (same as balance for debit-normal accounts)

credit_card.balance
# => -650.00 (negative means you owe money)

credit_card.normal_balance
# => 650.00 (flips the sign for credit-normal accounts)
```

## Generating Reports

### Trial Balance

```ruby
# Get all accounts with balances
Account.active.includes(:entries).map do |account|
  balance = account.balance
  {
    account: account.full_name,
    code: account.code,
    debit: balance > 0 ? balance : nil,
    credit: balance < 0 ? -balance : nil
  }
end
```

### Income Statement (for a date range)

```ruby
start_date = Date.new(2024, 10, 1)
end_date = Date.new(2024, 10, 31)

income_total = Account.income_accounts.sum do |account|
  -account.balance(as_of_date: end_date) + account.balance(as_of_date: start_date - 1.day)
end

expense_total = Account.expenses.sum do |account|
  account.balance(as_of_date: end_date) - account.balance(as_of_date: start_date - 1.day)
end

net_income = income_total - expense_total
```

### Account Ledger

```ruby
account = Account.find_by!(code: "1000")

entries = account.entries
  .includes(:transaction)
  .where(transactions: { status: "posted" })
  .order("transactions.date ASC, entries.created_at ASC")

running_balance = 0

entries.each do |entry|
  running_balance += entry.signed_amount

  puts "#{entry.transaction_date} | #{entry.transaction_description} | " \
       "#{entry.debit? ? entry.amount : ''} | " \
       "#{entry.credit? ? entry.amount : ''} | " \
       "#{running_balance}"
end
```

## Account Hierarchy Example

```ruby
# Create parent asset account
current_assets = Account.create!(
  code: "1000",
  name: "Current Assets",
  account_type: "asset"
)

# Create child accounts
checking = Account.create!(
  code: "1100",
  name: "Checking Account",
  account_type: "asset",
  parent: current_assets
)

savings = Account.create!(
  code: "1200",
  name: "Savings Account",
  account_type: "asset",
  parent: current_assets
)

# Query the hierarchy
current_assets.children
# => [checking, savings]

checking.full_name
# => "Current Assets : Checking Account"

checking.full_code
# => "1000.1100"

# Get total for parent account (sum of all children)
total = current_assets.descendants.sum { |acc| acc.normal_balance }
```

## Using Nested Attributes in Forms

```ruby
# In a controller, you can build a transaction with entries
@transaction = Transaction.new(transaction_params)

# transaction_params might look like:
def transaction_params
  params.require(:transaction).permit(
    :date,
    :description,
    :reference,
    entries_attributes: [:account_id, :amount, :entry_type, :memo, :_destroy]
  )
end

# This allows you to create a transaction and its entries in one form submission
```

## Common Patterns

### Finding Unbalanced Draft Transactions

```ruby
Transaction.draft.reject(&:balanced?)
```

### Finding All Transactions for a Date Range

```ruby
Transaction.posted.between_dates(start_date, end_date).by_date
```

### Finding All Transactions Involving a Specific Account

```ruby
Transaction.for_account(checking).posted.by_date
```

### Getting Total Income for a Period

```ruby
Entry.posted
  .joins(:account)
  .where(accounts: { account_type: "income" })
  .where(entry_type: "credit")
  .joins(:transaction)
  .where(transactions: { date: start_date..end_date })
  .sum(:amount)
```

### Getting Total Expenses for a Period

```ruby
Entry.posted
  .joins(:account)
  .where(accounts: { account_type: "expense" })
  .where(entry_type: "debit")
  .joins(:transaction)
  .where(transactions: { date: start_date..end_date })
  .sum(:amount)
```
