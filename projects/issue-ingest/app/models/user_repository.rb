class UserRepository < ApplicationRecord
  belongs_to :user
  belongs_to :repository
end
