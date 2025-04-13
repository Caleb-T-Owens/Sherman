class SourcesController < ApplicationController
  before_action :set_source, only: [:show, :edit, :update, :destroy, :refetch]

  def index
    @sources = Source.all
  end

  def show
  end

  def new
    @source = Source.new
  end

  def create
    @source = Source.new(source_params)

    if @source.save
      redirect_to @source, notice: "Source was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @source.update(source_params)
      redirect_to @source, notice: "Source was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy
    redirect_to sources_path, notice: "Source was successfully deleted.", status: :see_other
  end

  def refetch
    @source.fetch_source
    redirect_to @source, notice: "Source was successfully refetched."
  end

  private

  def set_source
    @source = Source.find(params[:id])
  end

  def source_params
    params.require(:source).permit(:name, :git_url)
  end
end
