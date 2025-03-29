class Fund < ApplicationRecord
  has_many :fund_memberships, dependent: :destroy
  has_many :users, through: :fund_memberships
  has_many :transactions, dependent: :destroy
  has_many :contributions, through: :fund_memberships
  
  validates :name, presence: true
  validates :min_contribution, numericality: { greater_than_or_equal_to: 0 }
  validates :max_contribution, numericality: { greater_than_or_equal_to: :min_contribution }
  
  # Virtual attributes for form
  attr_accessor :min_contribution_dollars, :max_contribution_dollars
  
  def owner
    fund_memberships.find_by(role: :owner)&.user
  end
  
  def members
    users.joins(:fund_memberships).where(fund_memberships: { role: :member })
  end
  
  # Get recent transactions for this fund
  def recent_transactions(limit = 10)
    transactions.recent.limit(limit)
  end
  
  # Get total credits (positive transactions)
  def total_credits
    transactions.credits.sum(:amount)
  end
  
  # Get total debits (negative transactions)
  def total_debits
    transactions.debits.sum(:amount)
  end
  
  # Get the current balance of the fund
  def balance
    transactions.sum(:amount)
  end
  
  # Get formatted balance
  def formatted_balance
    amount_dollars = (balance.to_f / 100).round(2)
    format("$%.2f", amount_dollars)
  end
  
  # Get user specific transactions
  def user_transactions(user)
    transactions.where(user: user).recent
  end
  
  # Get user balance in this fund
  def user_balance(user)
    user_transactions(user).sum(:amount)
  end
  
  # Get formatted user balance
  def formatted_user_balance(user)
    amount_dollars = (user_balance(user).to_f / 100).round(2)
    format("$%.2f", amount_dollars)
  end
  
  # Get min contribution in dollars
  def min_contribution_dollars
    (min_contribution.to_f / 100).round(2)
  end
  
  # Get max contribution in dollars
  def max_contribution_dollars
    (max_contribution.to_f / 100).round(2)
  end
  
  # Format contribution range as currency string
  def formatted_contribution_range
    if min_contribution == 0 && max_contribution == 0
      "No contribution required"
    elsif min_contribution == 0
      "Up to #{format("$%.2f", max_contribution_dollars)} per month"
    elsif max_contribution == 0 || min_contribution == max_contribution
      "#{format("$%.2f", min_contribution_dollars)} per month"
    else
      "#{format("$%.2f", min_contribution_dollars)} - #{format("$%.2f", max_contribution_dollars)} per month"
    end
  end
  
  # Get all active contributions for this fund
  def active_contributions
    contributions.active
  end
  
  # Get total monthly contribution pledge amount
  def total_pledged_amount
    active_contributions.sum(:amount)
  end
  
  # Format total pledged amount as currency string
  def formatted_total_pledged
    amount_dollars = (total_pledged_amount.to_f / 100).round(2)
    format("$%.2f", amount_dollars)
  end
  
  # Get the number of members with active contributions
  def contributing_members_count
    active_contributions.count
  end
  
  # Process all pending monthly contributions
  def process_monthly_contributions
    processed = []
    
    active_contributions.each do |contribution|
      next unless contribution.needs_processing?
      
      if transaction = contribution.process_contribution
        processed << transaction
      end
    end
    
    processed
  end
end
