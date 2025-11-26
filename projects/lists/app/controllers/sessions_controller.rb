class SessionsController < ApplicationController
  def new
    render inertia: "Auth/Login"
  end

  def create
    user = User.find_by(email: session_params[:email])

    if user&.authenticate(session_params[:password])
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in successfully"
    else
      redirect_to login_path, inertia: { errors: { email: "Invalid email or password" } }
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Logged out successfully"
  end

  private

  def session_params
    params.permit(:email, :password)
  end
end
