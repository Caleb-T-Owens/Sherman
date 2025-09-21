class SyncRepositoryIssuesJob < ApplicationJob
  queue_as :default

  def perform(repository_id)
    repository = Repository.find(repository_id)

    # Initialize Octokit client with the repository's GitHub token
    client = Octokit::Client.new(access_token: repository.gh_token)

    # Fetch all issues (both open and closed)
    # Octokit automatically paginates, so we'll fetch all pages
    issues = []
    page = 1

    loop do
      batch = client.issues("#{repository.owner}/#{repository.repo}",
                           state: 'all',
                           per_page: 100,
                           page: page)
      break if batch.empty?
      issues.concat(batch)
      page += 1
    end

    # Sync each issue
    issues.each do |github_issue|
      # Skip pull requests (GitHub API returns PRs as issues too)
      next if github_issue.pull_request

      # Find or initialize issue
      issue = repository.issues.find_or_initialize_by(number: github_issue.number)

      # Update issue attributes
      issue.title = github_issue.title
      issue.description = github_issue.body || ""
      issue.status = github_issue.state == "open" ? "opened" : "closed"

      # Extract labels as tags
      issue.tags = github_issue.labels.map(&:name)

      # Save the issue
      issue.save!
    end

    Rails.logger.info "Successfully synced #{issues.size} issues for repository #{repository.full_name}"
  rescue Octokit::Unauthorized
    Rails.logger.error "GitHub token is invalid for repository #{repository.full_name}"
    raise "Invalid GitHub token"
  rescue Octokit::NotFound
    Rails.logger.error "Repository #{repository.full_name} not found on GitHub"
    raise "Repository not found on GitHub"
  rescue => e
    Rails.logger.error "Error syncing issues for repository #{repository.full_name}: #{e.message}"
    raise
  end
end
