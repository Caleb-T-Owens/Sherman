class Source < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :git_url, presence: true

  has_many :service_locations, dependent: :destroy

  after_create :fetch_source_later

  def fetched?
    last_fetched_at.present? && git.initialized?
  end

  def git
    Git.new(directory: source_directory, git_url:)
  end

  def fetch_source_later
    SourceFetchJob.perform_later(self)
  end

  def fetch_source
    SourceFetchJob.perform_now(self)
  end

  private

  def source_directory
    sources_directory = Rails.application.config.sources_directory
    source_directory = sources_directory.join(name)
    FileUtils.mkdir_p(source_directory)
    source_directory
  end
end
