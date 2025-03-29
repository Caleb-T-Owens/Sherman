class Contribution < ApplicationRecord
  belongs_to :fund_membership
  
  validates :amount, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :fund_membership, presence: true
  
  delegate :fund, :user, to: :fund_membership
  
  scope :active, -> { where(active: true) }
  
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
  
  # Process monthly contribution and create a transaction
  def process_contribution
    return false unless active?
    
    transaction = fund.transactions.create!(
      title: "Monthly contribution from #{user.name}",
      reason: "Automated monthly contribution",
      amount: amount,
      user: user
    )
    
    update(last_contributed_at: Time.current)
    transaction
  end
  
  # Check if the contribution needs to be processed this month
  def needs_processing?
    return true if last_contributed_at.nil?
    
    current_month = Time.current.beginning_of_month
    last_month = last_contributed_at.beginning_of_month
    
    current_month > last_month
  end
  
  # Pause contribution
  def pause
    update(active: false)
  end
  
  # Resume contribution
  def resume
    update(active: true)
  end
end
