class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :set_user, only: %i[ show edit update destroy ]
  before_action :ensure_current_user_or_admin, only: %i[ edit update destroy ]

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to after_authentication_url, notice: "Account created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      redirect_to user_url(@user), notice: "Your account was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    
    if @user == Current.user
      terminate_session
      redirect_to root_url, notice: "Your account has been deleted."
    else
      redirect_to users_url, notice: "User was successfully deleted."
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def ensure_current_user_or_admin
      unless @user == Current.user # || Current.user&.admin?
        redirect_to root_url, alert: "You don't have permission to do that."
      end
    end

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation, :name)
    end
end