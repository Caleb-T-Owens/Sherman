class RegistrationsController < ApplicationController
  def new
    render inertia: "Auth/Register"
  end

  def create
    user = User.new(user_params)

    if user.save
      session[:user_id] = user.id
      redirect_to root_path, notice: "Account created successfully"
    else
      redirect_to register_path, inertia: { errors: user.errors.to_hash }
    end
  end

  private

  def user_params
    params.permit(:email, :password, :password_confirmation)
  end
end
