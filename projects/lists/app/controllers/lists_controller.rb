class ListsController < ApplicationController
  def my
    sites = current_user.sites.order(created_at: :desc)
    render inertia: "Lists/My", props: {
      sites: sites.as_json(only: [:id, :url, :title, :description, :created_at])
    }
  end

  def create
    site = current_user.sites.build(site_params)

    if site.save
      redirect_to list_my_path, notice: "Site added successfully"
    else
      redirect_to list_my_path, alert: site.errors.full_messages.join(", ")
    end
  end

  private

  def site_params
    params.permit(:url, :title, :description)
  end
end
