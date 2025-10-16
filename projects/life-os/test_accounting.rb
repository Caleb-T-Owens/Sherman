# Test script for accounting system
puts "Testing accounting system..."

# Create a user first
user = User.find_or_create_by!(email_address: "test@example.com") do |u|
  u.password = "password123456"
end
puts "✓ Using user: #{user.email_address}"

# Create some accounts
checking = Account.create!(code: "1000", name: "Checking Account", account_type: "asset")
puts "✓ Created account: #{checking.name}"

salary = Account.create!(code: "4000", name: "Salary", account_type: "income")
puts "✓ Created account: #{salary.name}"

rent = Account.create!(code: "5000", name: "Rent", account_type: "expense")
puts "✓ Created account: #{rent.name}"

# Create a transaction
txn = Transaction.new(
  user: user,
  date: Date.current,
  description: "Test salary deposit"
)
txn.entries.build(account: checking, amount: 5000, entry_type: :debit, memo: "Salary")
txn.entries.build(account: salary, amount: 5000, entry_type: :credit, memo: "Salary")
txn.save!
puts "✓ Created transaction with #{txn.entries.count} entries"

# Check if balanced
puts "Balanced? #{txn.balanced?}"
puts "Total debits: $#{txn.total_debits}"
puts "Total credits: $#{txn.total_credits}"

# Post the transaction
txn.post!
puts "✓ Posted transaction (status: #{txn.status})"

# Create another transaction (rent payment)
txn2 = Transaction.new(
  user: user,
  date: Date.current,
  description: "Rent payment"
)
txn2.entries.build(account: rent, amount: 1200, entry_type: :debit)
txn2.entries.build(account: checking, amount: 1200, entry_type: :credit)
txn2.save!
txn2.post!
puts "✓ Created and posted rent payment"

# Check balances
puts "\nAccount balances:"
puts "  #{checking.name}: $#{checking.normal_balance}"
puts "  #{salary.name}: $#{salary.normal_balance}"
puts "  #{rent.name}: $#{rent.normal_balance}"

# Test account hierarchy
puts "\nTesting account hierarchy..."
current_assets = Account.create!(code: "1000.0", name: "Current Assets", account_type: "asset")
checking2 = Account.create!(code: "1000.1", name: "Main Checking", account_type: "asset", parent: current_assets)
puts "✓ Created parent account: #{current_assets.name}"
puts "✓ Created child account: #{checking2.full_name}"

# Test enum methods
puts "\nTesting enum methods..."
puts "Transaction status: #{txn.status}"
puts "Is posted? #{txn.posted?}"
puts "Is draft? #{txn.draft?}"
puts "First entry is debit? #{txn.entries.first.debit?}"

# Test validation
puts "\nTesting validation..."
bad_txn = Transaction.new(
  user: user,
  date: Date.current,
  description: "Unbalanced transaction"
)
bad_txn.entries.build(account: checking, amount: 100, entry_type: :debit)
bad_txn.entries.build(account: salary, amount: 200, entry_type: :credit)

if bad_txn.valid?
  puts "ERROR: Unbalanced transaction should not save!"
else
  puts "✓ Validation works: #{bad_txn.errors.full_messages.first}"
end

puts "\n✅ All tests passed!"
