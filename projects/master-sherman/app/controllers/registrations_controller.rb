class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_registration_url, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.permit(:email_address, :password, :password_confirmation))

    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Welcome! You have successfully signed up."
    else
      render :new, status: :unprocessable_entity
    end
  end
end 