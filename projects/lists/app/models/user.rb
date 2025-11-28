class User < ApplicationRecord
  has_secure_password

  has_many :sites, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email, with: ->(email) { email.strip.downcase }

  def admin?
    email == "hello@calebowens.com"
  end
end
