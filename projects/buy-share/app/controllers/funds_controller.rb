class FundsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fund, only: [:show, :edit, :update, :destroy]
  before_action :ensure_owner, only: [:edit, :update, :destroy]

  def index
    @funds = current_user.funds
  end

  def show
    @members = @fund.users
  end

  def new
    @fund = Fund.new
  end

  def create
    @fund = Fund.new(fund_params)
    
    # Convert dollar values to cents for storage
    process_dollar_values
    
    ActiveRecord::Base.transaction do
      if @fund.save
        # Create the owner membership
        @fund.fund_memberships.create!(user: current_user, role: :owner)
        redirect_to @fund, notice: "Fund was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end
  
  def edit
  end
  
  def update
    # Convert dollar values to cents for storage
    process_dollar_values
    
    if @fund.update(fund_params)
      redirect_to @fund, notice: "Fund was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @fund.destroy
    redirect_to funds_path, notice: "Fund was successfully deleted."
  end

  private
  
  def set_fund
    @fund = Fund.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to funds_path, alert: "Fund not found."
  end
  
  def ensure_owner
    unless @fund.owner == current_user
      redirect_to funds_path, alert: "You don't have permission to perform this action."
    end
  end

  def fund_params
    params.require(:fund).permit(:name, :description, :min_contribution, :max_contribution, 
                                 :min_contribution_dollars, :max_contribution_dollars)
  end
  
  def process_dollar_values
    # Convert dollar parameters to cents if provided
    if params[:fund][:min_contribution_dollars].present?
      @fund.min_contribution = (params[:fund][:min_contribution_dollars].to_f * 100).round
    end
    
    if params[:fund][:max_contribution_dollars].present?
      @fund.max_contribution = (params[:fund][:max_contribution_dollars].to_f * 100).round
    end
  end
end
