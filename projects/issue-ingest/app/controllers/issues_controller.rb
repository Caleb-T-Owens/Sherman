class IssuesController < ApplicationController
  before_action :set_repository

  def index
    @issues = @repository.issues.order(:number)
    @opened_issues = @issues.opened
    @closed_issues = @issues.closed
  end

  def sync
    # Trigger the sync job
    SyncRepositoryIssuesJob.perform_later(@repository.id)
    redirect_to repository_issues_path(@repository), notice: "Syncing issues from GitHub. This may take a few moments."
  end

  private

  def set_repository
    @repository = Current.user.repositories.find(params[:repository_id])
  end
end
