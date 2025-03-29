class FundMembership < ApplicationRecord
  belongs_to :user
  belongs_to :fund
  has_one :contribution, dependent: :destroy
  
  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :fund_id, message: "is already a member of this fund" }
  
  enum :role, { owner: 'owner', member: 'member' }
  
  # Create or update a monthly contribution pledge
  def set_monthly_contribution(amount)
    if contribution.present?
      contribution.update(amount: amount, active: true)
    else
      create_contribution(amount: amount)
    end
  end
  
  # Remove monthly contribution pledge
  def remove_monthly_contribution
    contribution&.destroy
  end
  
  # Pause monthly contribution
  def pause_monthly_contribution
    contribution&.pause
  end
  
  # Resume monthly contribution
  def resume_monthly_contribution
    contribution&.resume
  end
  
  # Get monthly contribution amount in cents (or nil if none)
  def monthly_contribution_amount
    contribution&.amount
  end
  
  # Get monthly contribution amount in dollars (or 0 if none)
  def monthly_contribution_dollars
    return 0 unless contribution&.amount
    (contribution.amount.to_f / 100).round(2)
  end
  
  # Format monthly contribution as currency string
  def formatted_monthly_contribution
    return "$0.00" unless contribution&.amount
    format("$%.2f", monthly_contribution_dollars)
  end
  
  # Check if this membership has an active monthly contribution
  def contributing?
    contribution&.active?
  end
end
