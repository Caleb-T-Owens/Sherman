class PagesController < ApplicationController
  skip_before_action :require_authentication

  def home
    @sites = Site.all
  end
end
