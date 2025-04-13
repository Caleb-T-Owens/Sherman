class SourceFetchJob < ApplicationJob
  def perform(source)
    puts "Fetching source #{source.name}"

    git = source.git

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
