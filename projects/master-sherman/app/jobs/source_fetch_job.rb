class SourceFetchJob < ApplicationJob
  def perform(source)
    sources_directory = Rails.application.config.sources_directory

    puts "Fetching source #{source.name}"

    source_directory = sources_directory.join(source.name)
    FileUtils.mkdir_p(source_directory)

    git = Git.new(
      directory: source_directory,
      git_url: source.git_url
    )

    if git.initialized?
      puts "Pulling source #{source.name}"
      git.pull
    else
      puts "Cloning source #{source.name}"
      git.clone
    end

    source.touch(:last_fetched_at)
    puts "Source #{source.name} fetched at #{source.last_fetched_at}"
  end
end
