namespace :sources do
  desc "Fetch sources from the database"
  task fetch: :environment do
    Source.all.each do |source|
      SourceFetchJob.perform_now(source)
    end
  end
end
