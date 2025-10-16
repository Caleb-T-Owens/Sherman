class Account < ApplicationRecord
  # Account types and their normal balance directions
  TYPES = {
    "asset" => "debit",
    "expense" => "debit",
    "liability" => "credit",
    "equity" => "credit",
    "income" => "credit"
  }.freeze

  # Associations
  belongs_to :parent, class_name: "Account", optional: true
  has_many :children, class_name: "Account", foreign_key: "parent_id", dependent: :restrict_with_error
  has_many :entries, dependent: :restrict_with_error

  # Validations
  validates :code, presence: true, uniqueness: true, format: { with: /\A[\w\.\-]+\z/, message: "only allows letters, numbers, dots, and dashes" }
  validates :name, presence: true
  validates :account_type, presence: true, inclusion: { in: TYPES.keys }
  validate :parent_must_be_same_root_type

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :root_accounts, -> { where(parent_id: nil) }
  scope :by_type, ->(type) { where(account_type: type) }
  scope :assets, -> { by_type("asset") }
  scope :liabilities, -> { by_type("liability") }
  scope :equity_accounts, -> { by_type("equity") }
  scope :income_accounts, -> { by_type("income") }
  scope :expenses, -> { by_type("expense") }

  # Instance methods

  # Get the normal balance side for this account type
  def normal_balance_side
    TYPES[account_type]
  end

  # Is this a debit-normal account?
  def debit_normal?
    normal_balance_side == "debit"
  end

  # Is this a credit-normal account?
  def credit_normal?
    normal_balance_side == "credit"
  end

  # Calculate the balance for this account
  # For debit-normal accounts: debits increase, credits decrease
  # For credit-normal accounts: credits increase, debits decrease
  def balance(as_of_date: nil)
    scope = entries.joins(:accounting_transaction).where(transactions: { status: "posted" })
    scope = scope.where("transactions.date <= ?", as_of_date) if as_of_date

    debits = scope.debit.sum(:amount)
    credits = scope.credit.sum(:amount)

    debits - credits
  end

  # Get the balance with the sign adjusted for the normal balance side
  # Positive means the account is "increasing", negative means "decreasing"
  def normal_balance(as_of_date: nil)
    bal = balance(as_of_date: as_of_date)
    debit_normal? ? bal : -bal
  end

  # Full path of account names from root to this account
  def full_name
    if parent
      "#{parent.full_name} : #{name}"
    else
      name
    end
  end

  # Full path of account codes from root to this account
  def full_code
    if parent
      "#{parent.full_code}.#{code}"
    else
      code
    end
  end

  # Check if this account has any posted entries
  def has_posted_entries?
    entries.joins(:accounting_transaction).where(transactions: { status: "posted" }).exists?
  end

  # Deactivate account instead of destroying it
  def deactivate!
    update!(active: false)
  end

  # Get all ancestors (parent, grandparent, etc.)
  def ancestors
    return [] unless parent

    [parent] + parent.ancestors
  end

  # Get all descendants (children, grandchildren, etc.)
  def descendants
    children.flat_map { |child| [child] + child.descendants }
  end

  # Check if this is a leaf account (has no children)
  def leaf?
    children.empty?
  end

  private

  def parent_must_be_same_root_type
    if parent && parent.account_type != account_type
      errors.add(:parent, "must be the same account type (#{account_type})")
    end
  end
end
