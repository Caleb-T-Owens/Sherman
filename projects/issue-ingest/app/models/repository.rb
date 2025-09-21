class Repository < ApplicationRecord
  encrypts :gh_token

  has_many :user_repositories, dependent: :destroy
  has_many :users, through: :user_repositories

  validates :owner, presence: true
  validates :repo, presence: true
  validates :gh_token, presence: true
  validate :must_have_at_least_one_user

  def full_name
    "#{owner}/#{repo}"
  end

  private

  def must_have_at_least_one_user
    if users.empty? && user_repositories.empty?
      errors.add(:users, "must have at least one user")
    end
  end
end