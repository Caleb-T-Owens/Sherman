class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def image_url
    digest = Digest::SHA256.hexdigest(email_address)
    "https://www.gravatar.com/avatar/#{digest}?d=retro"
  end
end
