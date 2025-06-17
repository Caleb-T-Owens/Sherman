class Post < ApplicationRecord
  belongs_to :user
  has_many :likes, dependent: :destroy, counter_cache: true
  has_many :liked_users, through: :likes, source: :user

  validates :content, presence: true, length: { maximum: 1000 }

  def liked_by?(user)
    return false unless user
    likes.exists?(user:)
  end

  def like_for(user)
    likes.find_by(user:)
  end
end
