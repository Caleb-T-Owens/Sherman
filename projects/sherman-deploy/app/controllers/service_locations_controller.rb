class ServiceLocationsController < ApplicationController
  before_action :set_source
  before_action :set_service_location, only: [:show, :edit, :update, :destroy]
  
  def index
    @service_locations = @source.service_locations
  end
  
  def show
  end

  def new
    @service_location = @source.service_locations.build
  end

  def create
    @service_location = @source.service_locations.build(service_location_params)
    
    if @service_location.save
      redirect_to source_service_locations_path(@source), notice: "Service location was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @service_location.update(service_location_params)
      redirect_to source_service_locations_path(@source), notice: "Service location was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service_location.destroy
    redirect_to source_service_locations_path(@source), notice: "Service location was successfully destroyed."
  end
  
  private
  
  def set_source
    @source = Source.find(params[:source_id])
  end
  
  def set_service_location
    @service_location = @source.service_locations.find(params[:id])
  end
  
  def service_location_params
    params.require(:service_location).permit(:name, :path)
  end
end
