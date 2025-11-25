class ListsController < ApplicationController
  before_action :authenticate_user!

  def my
    sites = current_user.sites.order(created_at: :desc)
    render inertia: "Lists/My", props: {
      sites: sites.as_json(only: [ :id, :url, :title, :description, :created_at ])
    }
  end
end
