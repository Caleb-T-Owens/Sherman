class Entry < ApplicationRecord
  # Associations
  # Note: Can't use "transaction" as association name since it conflicts with ActiveRecord method
  belongs_to :accounting_transaction, class_name: "Transaction", foreign_key: "transaction_id", inverse_of: :entries
  belongs_to :account

  # Enum with string values for readable database storage
  # This auto-generates: debit?, credit? predicate methods
  # This auto-generates: debit, credit scopes
  enum :entry_type, { debit: "debit", credit: "credit" }

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }

  # Scopes
  scope :posted, -> { joins(:accounting_transaction).where(transactions: { status: "posted" }) }
  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :by_date, -> { joins(:accounting_transaction).order("transactions.date DESC, entries.created_at DESC") }

  # Delegations for convenience
  delegate :date, :description, :reference, :posted?, to: :accounting_transaction, prefix: false

  # Instance methods

  # Get the signed amount based on entry type and account normal balance
  # Positive means increasing the account, negative means decreasing
  def signed_amount
    if account.debit_normal?
      debit? ? amount : -amount
    else
      credit? ? amount : -amount
    end
  end

  # Format for display in ledgers
  def display_amount
    if debit?
      { debit: amount, credit: nil }
    else
      { debit: nil, credit: amount }
    end
  end
end
