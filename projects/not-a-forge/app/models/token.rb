class Token < ApplicationRecord
  belongs_to :user
  has_many :repositories, dependent: :nullify

  encrypts :token

  validates :name, presence: true
  validates :token, presence: true
  validates :name, uniqueness: { scope: :user_id, message: "has already been used for another token" }
end
