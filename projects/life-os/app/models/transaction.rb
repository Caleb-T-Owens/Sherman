class Transaction < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :entries, dependent: :destroy, inverse_of: :accounting_transaction
  accepts_nested_attributes_for :entries, allow_destroy: true, reject_if: :all_blank

  # Enum with string values for readable database storage
  # This auto-generates: draft?, posted?, void? predicate methods
  # This auto-generates: draft, posted, void scopes
  # We override the bang methods below to add business logic
  enum :status, { draft: "draft", posted: "posted", void: "void" }, default: :draft

  # Validations
  validates :date, presence: true
  validates :description, presence: true
  validate :must_have_at_least_two_entries
  validate :debits_must_equal_credits
  validate :cannot_modify_if_posted, on: :update

  # Scopes
  scope :not_voided, -> { where.not(status: "void") }
  scope :by_date, -> { order(date: :desc, created_at: :desc) }
  scope :for_account, ->(account) { joins(:entries).where(entries: { account_id: account.id }).distinct }
  scope :between_dates, ->(start_date, end_date) { where(date: start_date..end_date) }

  # Callbacks
  before_validation :set_default_date, on: :create

  # Instance methods

  # Post this transaction (make it immutable and affect account balances)
  # Overrides the enum-generated post! to add business logic
  def post!
    raise "Transaction must be valid before posting" unless valid_for_posting?
    raise "Transaction is already posted" if posted?

    update!(status: :posted, posted_at: Time.current)
  end

  # Void this transaction (keep it for audit trail but don't affect balances)
  # Overrides the enum-generated void! to add business logic
  def void!
    raise "Cannot void a draft transaction" if draft?
    raise "Transaction is already voided" if void?

    update!(status: :void)
  end

  # Check if transaction is valid for posting
  def valid_for_posting?
    entries.size >= 2 && balanced?
  end

  # Check if debits equal credits
  def balanced?
    total_debits == total_credits
  end

  # Calculate total debits
  def total_debits
    entries.debit.sum(:amount)
  end

  # Calculate total credits
  def total_credits
    entries.credit.sum(:amount)
  end

  # Get the difference between debits and credits
  def balance_difference
    total_debits - total_credits
  end

  # Create a reversing transaction (to correct a posted transaction)
  def create_reversing_transaction(description_suffix: "REVERSAL")
    raise "Can only reverse posted transactions" unless posted?

    reversing = self.class.new(
      date: Date.current,
      description: "#{description} [#{description_suffix}]",
      reference: reference,
      user: user,
      status: :draft
    )

    entries.each do |entry|
      reversing.entries.build(
        account: entry.account,
        amount: entry.amount,
        entry_type: entry.debit? ? :credit : :debit,
        memo: entry.memo ? "Reversal: #{entry.memo}" : "Reversal"
      )
    end

    reversing
  end

  private

  def set_default_date
    self.date ||= Date.current
  end

  def must_have_at_least_two_entries
    if entries.reject(&:marked_for_destruction?).size < 2
      errors.add(:base, "Transaction must have at least two entries")
    end
  end

  def debits_must_equal_credits
    return if entries.empty? || entries.all?(&:marked_for_destruction?)

    valid_entries = entries.reject(&:marked_for_destruction?)
    debits = valid_entries.select(&:debit?).sum(&:amount)
    credits = valid_entries.select(&:credit?).sum(&:amount)

    unless debits == credits
      errors.add(:base, "Total debits (#{debits}) must equal total credits (#{credits})")
    end
  end

  def cannot_modify_if_posted
    if status_in_database == "posted" && !status_changed?
      errors.add(:base, "Cannot modify a posted transaction. Create a reversing transaction instead.")
    end

    # Allow status changes from posted to void
    if status_in_database == "posted" && status_changed? && !void?
      errors.add(:status, "Posted transactions can only be voided, not changed to #{status}")
    end
  end
end
