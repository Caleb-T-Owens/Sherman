class FundMembership < ApplicationRecord
  belongs_to :user
  belongs_to :fund
  
  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :fund_id, message: "is already a member of this fund" }
  
  enum :role, { owner: 'owner', member: 'member' }
end
