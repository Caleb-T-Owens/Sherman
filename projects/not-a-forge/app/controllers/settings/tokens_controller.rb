class Settings::TokensController < ApplicationController
  layout "settings"
  before_action :set_token, only: [:edit, :update, :destroy]

  def index
    @tokens = Current.user.tokens.order(created_at: :desc)
  end

  def new
    @token = Current.user.tokens.build
  end

  def create
    @token = Current.user.tokens.build(token_params)

    if @token.save
      redirect_to settings_tokens_path, notice: "Token '#{@token.name}' was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Only allow updating the name, not the token itself
    if @token.update(name: token_params[:name])
      redirect_to settings_tokens_path, notice: "Token name updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @token.destroy
    redirect_to settings_tokens_path, notice: "Token was successfully deleted."
  end

  private

  def set_token
    @token = Current.user.tokens.find(params[:id])
  end

  def token_params
    params.require(:token).permit(:name, :token)
  end
end
