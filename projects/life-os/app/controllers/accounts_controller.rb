class AccountsController < ApplicationController
  before_action :set_account, only: [ :show, :edit, :update ]

  def index
    @accounts = Account.active.order(:code)
    @accounts_by_type = @accounts.group_by(&:account_type)
  end

  def show
    @entries = @account.entries
      .includes(:accounting_transaction)
      .joins(:accounting_transaction)
      .where(transactions: { status: :posted })
      .order("transactions.date DESC, entries.created_at DESC")
      .limit(100)
  end

  def new
    @account = Account.new
    @parent_accounts = Account.active.order(:code)
  end

  def create
    @account = Account.new(account_params)

    if @account.save
      redirect_to accounts_path, notice: "Account created successfully."
    else
      @parent_accounts = Account.active.order(:code)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @parent_accounts = Account.active.where.not(id: @account.id).order(:code)
  end

  def update
    if @account.has_posted_entries?
      # Only allow limited updates if account has posted entries
      restricted_params = account_params.slice(:name, :description, :active)
      if @account.update(restricted_params)
        redirect_to @account, notice: "Account updated successfully."
      else
        @parent_accounts = Account.active.where.not(id: @account.id).order(:code)
        render :edit, status: :unprocessable_entity
      end
    else
      if @account.update(account_params)
        redirect_to @account, notice: "Account updated successfully."
      else
        @parent_accounts = Account.active.where.not(id: @account.id).order(:code)
        render :edit, status: :unprocessable_entity
      end
    end
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end

  def account_params
    params.require(:account).permit(:code, :name, :account_type, :parent_id, :description, :active)
  end
end
