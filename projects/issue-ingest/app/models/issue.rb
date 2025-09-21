class Issue < ApplicationRecord
  belongs_to :repository

  enum :status, { opened: 0, closed: 1 }

  validates :number, presence: true, uniqueness: { scope: :repository_id }
  validates :title, presence: true
  validates :status, presence: true

  before_validation :ensure_tags_is_array

  private

  def ensure_tags_is_array
    self.tags = [] unless tags.is_a?(Array)
    self.tags = tags.select { |tag| tag.is_a?(String) } if tags.is_a?(Array)
  end
end
