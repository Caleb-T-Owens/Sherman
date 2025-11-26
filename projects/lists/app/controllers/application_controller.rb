class ApplicationController < ActionController::Base
  inertia_share app_name: "Lists"
  inertia_share current_user: -> {
    if current_user
      { id: current_user.id, email: current_user.email }
    end
  }

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protected

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def authenticate_user!
    redirect_to login_path unless current_user
  end
end
