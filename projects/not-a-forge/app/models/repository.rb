class Repository < ApplicationRecord
  belongs_to :user
  belongs_to :token, optional: true

  validates :owner, presence: true
  validates :name, presence: true
  validates :owner, uniqueness: { scope: [:user_id, :name], message: "and name combination already exists" }

  # Returns the full repository name in owner/name format
  def full_name
    "#{owner}/#{name}"
  end
end
