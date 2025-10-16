# Accounting System Quick Start

This guide will help you get the accounting system up and running.

## Installation

1. Run the migrations:

```bash
cd projects/life-os
rails db:migrate
```

2. Verify the tables were created:

```bash
rails dbconsole
.tables  # Should show: accounts, entries, transactions (among others)
.quit
```

## Setting Up Your Chart of Accounts

You'll want to set up a basic chart of accounts. Here's a recommended starting structure:

```ruby
# In rails console or a seed file

user = User.first # or Current.user in the app

# == ASSETS (1000-1999) ==
checking = Account.create!(
  code: "1000",
  name: "Checking Account",
  account_type: "asset",
  description: "Primary checking account"
)

savings = Account.create!(
  code: "1100",
  name: "Savings Account",
  account_type: "asset"
)

cash = Account.create!(
  code: "1200",
  name: "Cash",
  account_type: "asset",
  description: "Cash on hand"
)

# == LIABILITIES (2000-2999) ==
credit_card = Account.create!(
  code: "2000",
  name: "Credit Card",
  account_type: "liability",
  description: "Primary credit card"
)

# == EQUITY (3000-3999) ==
opening_balances = Account.create!(
  code: "3000",
  name: "Opening Balances",
  account_type: "equity",
  description: "Account for recording initial balances"
)

# == INCOME (4000-4999) ==
salary = Account.create!(
  code: "4000",
  name: "Salary",
  account_type: "income"
)

interest_income = Account.create!(
  code: "4100",
  name: "Interest Income",
  account_type: "income"
)

# == EXPENSES (5000-5999) ==
rent = Account.create!(
  code: "5000",
  name: "Rent",
  account_type: "expense"
)

groceries = Account.create!(
  code: "5100",
  name: "Groceries",
  account_type: "expense"
)

utilities = Account.create!(
  code: "5200",
  name: "Utilities",
  account_type: "expense"
)

transportation = Account.create!(
  code: "5300",
  name: "Transportation",
  account_type: "expense"
)

entertainment = Account.create!(
  code: "5400",
  name: "Entertainment",
  account_type: "expense"
)

dining = Account.create!(
  code: "5500",
  name: "Dining Out",
  account_type: "expense"
)
```

## Recording Your Opening Balances

Before you start tracking transactions, record your current account balances:

```ruby
# Example: You have $5,000 in checking and owe $1,200 on credit card

transaction = Transaction.create!(
  user: user,
  date: Date.current,
  description: "Opening balances",
  status: "draft"
)

# Checking account balance
transaction.entries.create!(
  account: checking,
  amount: 5000.00,
  entry_type: "debit",
  memo: "Opening balance"
)

# Credit card balance (liability, so we credit it to increase)
transaction.entries.create!(
  account: credit_card,
  amount: 1200.00,
  entry_type: "credit",
  memo: "Opening balance"
)

# Offset goes to equity (the difference is what you're worth)
transaction.entries.create!(
  account: opening_balances,
  amount: 3800.00,
  entry_type: "credit",
  memo: "Net opening equity"
)

transaction.post!
```

## Your First Real Transaction

Let's record buying groceries:

```ruby
transaction = Transaction.create!(
  user: user,
  date: Date.current,
  description: "Grocery shopping at Safeway",
  status: "draft"
)

# Increase expense
transaction.entries.create!(
  account: groceries,
  amount: 127.50,
  entry_type: "debit"
)

# Decrease checking account
transaction.entries.create!(
  account: checking,
  amount: 127.50,
  entry_type: "credit"
)

transaction.post!
```

## Checking Your Work

### Verify the transaction is balanced

```ruby
transaction.balanced?
# => true

transaction.total_debits
# => 127.50

transaction.total_credits
# => 127.50
```

### Check account balance

```ruby
checking.balance
# => 4872.50 (5000.00 - 127.50)

groceries.balance
# => 127.50
```

### View the transaction

```ruby
transaction.entries.each do |entry|
  puts "#{entry.account.name}: #{entry.entry_type} #{entry.amount}"
end
# Groceries: debit 127.50
# Checking Account: credit 127.50
```

## Common Transaction Types

### Recording Income

```ruby
# Salary deposit
t = Transaction.create!(user: user, date: Date.current, description: "Salary", status: "draft")
t.entries.create!(account: checking, amount: 3500, entry_type: "debit")  # Money in
t.entries.create!(account: salary, amount: 3500, entry_type: "credit")   # Income
t.post!
```

### Paying a Bill

```ruby
# Rent payment
t = Transaction.create!(user: user, date: Date.current, description: "Rent", status: "draft")
t.entries.create!(account: rent, amount: 1200, entry_type: "debit")      # Expense
t.entries.create!(account: checking, amount: 1200, entry_type: "credit") # Money out
t.post!
```

### Credit Card Purchase

```ruby
# Dinner on credit card
t = Transaction.create!(user: user, date: Date.current, description: "Dinner", status: "draft")
t.entries.create!(account: dining, amount: 65, entry_type: "debit")        # Expense
t.entries.create!(account: credit_card, amount: 65, entry_type: "credit")  # Debt increases
t.post!
```

### Paying Credit Card

```ruby
# Pay off some credit card balance
t = Transaction.create!(user: user, date: Date.current, description: "Credit card payment", status: "draft")
t.entries.create!(account: credit_card, amount: 500, entry_type: "debit")  # Reduce debt
t.entries.create!(account: checking, amount: 500, entry_type: "credit")    # Money out
t.post!
```

### Transfer Between Accounts

```ruby
# Move money from checking to savings
t = Transaction.create!(user: user, date: Date.current, description: "Transfer to savings", status: "draft")
t.entries.create!(account: savings, amount: 1000, entry_type: "debit")   # Money in savings
t.entries.create!(account: checking, amount: 1000, entry_type: "credit") # Money out of checking
t.post!
```

## Generating Basic Reports

### Simple Income Statement (Month to Date)

```ruby
start_date = Date.current.beginning_of_month
end_date = Date.current

puts "Income Statement"
puts "#{start_date} to #{end_date}"
puts "-" * 40

total_income = 0
Account.income_accounts.each do |account|
  amount = account.entries
    .posted
    .joins(:transaction)
    .where(transactions: { date: start_date..end_date })
    .where(entry_type: "credit")
    .sum(:amount)

  if amount > 0
    puts "#{account.name.ljust(30)} #{amount}"
    total_income += amount
  end
end

puts "-" * 40
puts "Total Income: #{total_income}"
puts ""

total_expenses = 0
Account.expenses.each do |account|
  amount = account.entries
    .posted
    .joins(:transaction)
    .where(transactions: { date: start_date..end_date })
    .where(entry_type: "debit")
    .sum(:amount)

  if amount > 0
    puts "#{account.name.ljust(30)} #{amount}"
    total_expenses += amount
  end
end

puts "-" * 40
puts "Total Expenses: #{total_expenses}"
puts ""
puts "Net Income: #{total_income - total_expenses}"
```

### Simple Balance Sheet (Current Balances)

```ruby
puts "Balance Sheet"
puts "As of #{Date.current}"
puts "-" * 40

puts "\nASSETS"
total_assets = 0
Account.assets.each do |account|
  balance = account.normal_balance
  if balance > 0
    puts "  #{account.name.ljust(30)} #{balance}"
    total_assets += balance
  end
end
puts "Total Assets: #{total_assets}"

puts "\nLIABILITIES"
total_liabilities = 0
Account.liabilities.each do |account|
  balance = account.normal_balance
  if balance > 0
    puts "  #{account.name.ljust(30)} #{balance}"
    total_liabilities += balance
  end
end
puts "Total Liabilities: #{total_liabilities}"

puts "\nEQUITY"
total_equity = 0
Account.equity_accounts.each do |account|
  balance = account.normal_balance
  if balance > 0
    puts "  #{account.name.ljust(30)} #{balance}"
    total_equity += balance
  end
end
puts "Total Equity: #{total_equity}"

puts "\n" + "=" * 40
puts "Total Liabilities + Equity: #{total_liabilities + total_equity}"
puts "(Should equal Total Assets: #{total_assets})"
```

## Tips for Success

1. **Post transactions regularly**: Don't leave too many in draft status
2. **Use descriptive names**: Future you will thank you
3. **Be consistent with account codes**: Stick to your numbering scheme
4. **Reconcile with bank statements**: Check your balances match reality
5. **Use the memo field**: Add details that might be useful later
6. **Create reversals for mistakes**: Don't try to edit posted transactions

## Next Steps

- Set up controllers and views for web interface
- Create forms for transaction entry
- Build report pages
- Add reconciliation features
- Consider recurring transaction support

See `accounting_design.md` for architectural details and `accounting_examples.md` for more complex examples.
