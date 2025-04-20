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
    ProcessLater.perform_later(self, :fetch_source)
  end

  def fetch_source
    puts "Fetching source #{name}"

    if git.initialized?
      puts "Pulling source #{name}"
      git.pull
    else
      puts "Cloning source #{name}"
      git.clone
    end

    touch(:last_fetched_at)
    puts "Source #{name} fetched at #{last_fetched_at}"
  end

  def checkout_directory
    source_directory.join("checkout")
  end

  def source_directory
    sources_directory = Rails.application.config.sources_directory
    source_directory = sources_directory.join(name)
    FileUtils.mkdir_p(source_directory)
    source_directory
  end
end
