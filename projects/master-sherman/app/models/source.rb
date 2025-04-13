class Source < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :git_url, presence: true

  after_create :fetch_source

  private

  def fetch_source
    SourceFetchJob.perform_later(self)
  end
end
