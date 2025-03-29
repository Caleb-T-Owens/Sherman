class User < ApplicationRecord
  has_secure_password
  
  has_many :fund_memberships, dependent: :destroy
  has_many :funds, through: :fund_memberships
  has_many :transactions, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_digest_changed?
  validates :name, presence: true
  
  def owned_funds
    funds.joins(:fund_memberships).where(fund_memberships: { user_id: id, role: :owner })
  end
  
  def member_funds
    funds.joins(:fund_memberships).where(fund_memberships: { user_id: id, role: :member })
  end
  
  # Get recent transactions for this user
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
  
  # Get balance for this user
  def balance
    transactions.sum(:amount)
  end
  
  # Get formatted balance
  def formatted_balance
    amount_dollars = (balance.to_f / 100).round(2)
    format("$%.2f", amount_dollars)
  end
end
