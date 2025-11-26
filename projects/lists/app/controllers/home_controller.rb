class HomeController < ApplicationController
  def index
    render inertia: "Home"
  end
end
