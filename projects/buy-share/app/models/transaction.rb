class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :fund
  
  validates :title, presence: true
  validates :amount, presence: true, numericality: { only_integer: true }
  
  # Convert decimal amount to cents when assigning
  def amount=(value)
    if value.is_a?(String) && value.include?('.')
      super((value.to_f * 100).round)
    elsif value.is_a?(Float)
      super((value * 100).round)
    else
      super(value)
    end
  end
  
  # Get amount in dollars (float)
  def amount_dollars
    (amount.to_f / 100).round(2)
  end
  
  # Format amount as currency string
  def formatted_amount
    format("$%.2f", amount_dollars)
  end
  
  # Positive transaction (credit)
  def credit?
    amount > 0
  end
  
  # Negative transaction (debit)
  def debit?
    amount < 0
  end
  
  # Scope for credits
  scope :credits, -> { where('amount > 0') }
  
  # Scope for debits
  scope :debits, -> { where('amount < 0') }
  
  # Scope for recent transactions
  scope :recent, -> { order(created_at: :desc) }
end
