class TransactionsController < ApplicationController
  before_action :set_transaction, only: [ :show, :edit, :update, :destroy, :post_transaction, :void_transaction ]

  def index
    @transactions = Current.user.transactions
      .includes(:entries)
      .order(date: :desc, created_at: :desc)
      .limit(100)
  end

  def show
    @entries = @transaction.entries.includes(:account).order(:id)
  end

  def new
    @transaction = Current.user.transactions.build(date: Date.current)
    # Start with 2 empty entries
    2.times { @transaction.entries.build }
    @accounts = Account.active.order(:code)
  end

  def create
    @transaction = Current.user.transactions.build(transaction_params)

    if @transaction.save
      redirect_to @transaction, notice: "Transaction created successfully."
    else
      @accounts = Account.active.order(:code)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @transaction.draft?
      redirect_to @transaction, alert: "Cannot edit a #{@transaction.status} transaction. Create a reversing transaction instead."
      return
    end

    # Ensure at least 2 entry fields
    while @transaction.entries.size < 2
      @transaction.entries.build
    end

    @accounts = Account.active.order(:code)
  end

  def update
    unless @transaction.draft?
      redirect_to @transaction, alert: "Cannot update a #{@transaction.status} transaction."
      return
    end

    if @transaction.update(transaction_params)
      redirect_to @transaction, notice: "Transaction updated successfully."
    else
      @accounts = Account.active.order(:code)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @transaction.draft?
      redirect_to @transaction, alert: "Cannot delete a #{@transaction.status} transaction. Void it instead."
      return
    end

    @transaction.destroy
    redirect_to transactions_path, notice: "Transaction deleted successfully."
  end

  def post_transaction
    begin
      @transaction.post!
      redirect_to @transaction, notice: "Transaction posted successfully."
    rescue => e
      redirect_to @transaction, alert: "Could not post transaction: #{e.message}"
    end
  end

  def void_transaction
    begin
      @transaction.void!
      redirect_to @transaction, notice: "Transaction voided successfully."
    rescue => e
      redirect_to @transaction, alert: "Could not void transaction: #{e.message}"
    end
  end

  private

  def set_transaction
    @transaction = Current.user.transactions.find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(
      :date,
      :description,
      :reference,
      entries_attributes: [ :id, :account_id, :amount, :entry_type, :memo, :_destroy ]
    )
  end
end
