class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fund
  before_action :ensure_member
  before_action :set_transaction, only: [:destroy]
  
  def index
    @transactions = @fund.transactions.includes(:user).recent
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @transaction = @fund.transactions.build(transaction_params)
    @transaction.user = current_user
    
    respond_to do |format|
      if @transaction.save
        format.turbo_stream { 
          render turbo_stream: [
            turbo_stream.prepend("transactions", partial: "transactions/transaction", locals: { transaction: @transaction }),
            turbo_stream.replace("transaction-form", partial: "transactions/form", locals: { fund: @fund, transaction: @fund.transactions.build }),
            turbo_stream.replace("fund-balance", partial: "funds/balance", locals: { fund: @fund }),
            turbo_stream.replace("user-balance", partial: "funds/user_balance", locals: { fund: @fund, user: current_user })
          ]
        }
        format.html { redirect_to fund_path(@fund), notice: "Transaction was successfully created." }
      else
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace("transaction-form", 
            partial: "transactions/form", 
            locals: { fund: @fund, transaction: @transaction })
        }
        format.html { render "funds/show" }
      end
    end
  end
  
  def destroy
    @transaction.destroy
    
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: [
          turbo_stream.remove(@transaction),
          turbo_stream.replace("fund-balance", partial: "funds/balance", locals: { fund: @fund }),
          turbo_stream.replace("user-balance", partial: "funds/user_balance", locals: { fund: @fund, user: current_user })
        ]
      }
      format.html { redirect_to fund_path(@fund), notice: "Transaction was successfully deleted." }
    end
  end
  
  private
  
  def set_fund
    @fund = Fund.find(params[:fund_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to funds_path, alert: "Fund not found."
  end
  
  def set_transaction
    @transaction = @fund.transactions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to fund_path(@fund), alert: "Transaction not found."
  end
  
  def ensure_member
    unless @fund.users.include?(current_user)
      redirect_to funds_path, alert: "You don't have permission to perform this action."
    end
  end
  
  def transaction_params
    params.require(:transaction).permit(:title, :reason, :amount, :amount_dollars)
  end
end
