class RepositoriesController < ApplicationController
  before_action :set_repository, only: [:show, :edit, :update, :destroy]

  def index
    @repositories = Current.user.repositories
  end

  def show
  end

  def new
    @repository = Repository.new
  end

  def create
    @repository = Repository.new(repository_params)
    @repository.users << Current.user

    if @repository.save
      redirect_to @repository, notice: "Repository was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Don't update gh_token if it's blank (user wants to keep existing)
    update_params = repository_params
    if update_params[:gh_token].blank?
      update_params.delete(:gh_token)
    end

    if @repository.update(update_params)
      redirect_to @repository, notice: "Repository was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @repository.destroy
    redirect_to repositories_url, notice: "Repository was successfully deleted."
  end

  private

  def set_repository
    @repository = Current.user.repositories.find(params[:id])
  end

  def repository_params
    params.require(:repository).permit(:owner, :repo, :gh_token)
  end
end