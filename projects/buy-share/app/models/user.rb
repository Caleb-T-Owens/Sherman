class User < ApplicationRecord
  has_secure_password
  
  has_many :fund_memberships, dependent: :destroy
  has_many :funds, through: :fund_memberships
  
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 8 }, if: :password_digest_changed?
  validates :name, presence: true
  
  def owned_funds
    funds.joins(:fund_memberships).where(fund_memberships: { user_id: id, role: :owner })
  end
  
  def member_funds
    funds.joins(:fund_memberships).where(fund_memberships: { user_id: id, role: :member })
  end
end
