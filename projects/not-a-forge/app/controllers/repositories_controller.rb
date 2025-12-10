class RepositoriesController < ApplicationController
  before_action :set_repository, only: [ :edit, :update, :destroy, :show ]

  def show
    pp @repository.info
  end

  def index
    @repositories = Current.user.repositories.includes(:token).order(created_at: :desc)
  end

  def new
    @repository = Current.user.repositories.build
    @tokens = Current.user.tokens.order(:name)
  end

  def create
    @repository = Current.user.repositories.build(repository_params)

    if @repository.save
      redirect_to repositories_path, notice: "Repository '#{@repository.full_name}' was successfully added."
    else
      @tokens = Current.user.tokens.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @tokens = Current.user.tokens.order(:name)
  end

  def update
    if @repository.update(repository_params)
      redirect_to repositories_path, notice: "Repository updated successfully."
    else
      @tokens = Current.user.tokens.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @repository.destroy
    redirect_to repositories_path, notice: "Repository was successfully removed."
  end

  private

  def set_repository
    @repository = Current.user.repositories.find(params[:id])
  end

  def repository_params
    params.require(:repository).permit(:owner, :name, :token_id)
  end
end
