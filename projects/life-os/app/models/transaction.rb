class Transaction < ApplicationRecord
  belongs_to :source, class_name: 'Account'
  belongs_to :destination, class_name: 'Account'
end
