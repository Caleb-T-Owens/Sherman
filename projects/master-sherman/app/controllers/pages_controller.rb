class PagesController < ApplicationController
  allow_unauthenticated_access only: :home

  def home
  end

  def dashboard
  end
end 