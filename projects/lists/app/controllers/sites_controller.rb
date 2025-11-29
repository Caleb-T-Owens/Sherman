class SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site, only: %i[destroy update]

  def create
    site = current_user.sites.build(site_params)

    if site.save
      redirect_to list_my_path, notice: "Site added successfully"
    else
      redirect_to list_my_path, alert: site.errors.full_messages.join(", ")
    end
  end

  def update
    if @site.update(site_params)
      redirect_to list_my_path, notice: "Site updated successfully"
    else
      redirect_to list_my_path, alert: "Failed to destroy site"
    end
  end

  def destroy
    if @site.destroy
      redirect_to list_my_path, notice: "Site destroyed successfully"
    else
      redirect_to list_my_path, alert: "Failed to destroy site"
    end
  end

  private

  def site_params
    params.permit(:url, :title, :description)
  end

  def set_site
    @site = Site.find(params[:id])
  end
end
