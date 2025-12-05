class Settings::ProfilesController < ApplicationController
  layout "settings"
  before_action :set_user

  def show
  end

  def edit
  end

  def update
    if update_params[:password].present?
      # If updating password, require current password and validate new password
      unless @user.authenticate(update_params[:current_password])
        @user.errors.add(:current_password, "is incorrect")
        render :edit, status: :unprocessable_entity
        return
      end

      if update_params[:password] != update_params[:password_confirmation]
        @user.errors.add(:password_confirmation, "doesn't match password")
        render :edit, status: :unprocessable_entity
        return
      end
    end

    if @user.update(user_update_params)
      redirect_to settings_profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Require password confirmation for account deletion
    unless @user.authenticate(params[:current_password])
      redirect_to settings_profile_path, alert: "Incorrect password. Account was not deleted."
      return
    end

    @user.destroy
    reset_authentication
    redirect_to root_path, notice: "Your account has been deleted."
  end

  private

  def set_user
    @user = Current.user
  end

  def update_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :current_password)
  end

  def user_update_params
    # Only include password if it's being changed
    if update_params[:password].present?
      { email_address: update_params[:email_address], password: update_params[:password] }
    else
      { email_address: update_params[:email_address] }
    end
  end
end
