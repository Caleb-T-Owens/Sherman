class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    # Redirect authenticated users to their dashboard
    redirect_to repositories_path if authenticated?
  end
end
