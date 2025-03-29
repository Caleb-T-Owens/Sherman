class Fund < ApplicationRecord
  has_many :fund_memberships, dependent: :destroy
  has_many :users, through: :fund_memberships
  
  validates :name, presence: true
  
  def owner
    fund_memberships.find_by(role: :owner)&.user
  end
  
  def members
    users.joins(:fund_memberships).where(fund_memberships: { role: :member })
  end
end
