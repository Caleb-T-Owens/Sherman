class ReportsController < ApplicationController
  def trial_balance
    @as_of_date = params[:as_of_date] ? Date.parse(params[:as_of_date]) : Date.current
    @accounts = Account.active.order(:account_type, :code)

    @accounts_with_balances = @accounts.map do |account|
      balance = account.balance(as_of_date: @as_of_date)
      {
        account: account,
        balance: balance,
        debit_balance: balance > 0 ? balance : 0,
        credit_balance: balance < 0 ? -balance : 0
      }
    end.reject { |data| data[:balance].zero? }

    @total_debits = @accounts_with_balances.sum { |data| data[:debit_balance] }
    @total_credits = @accounts_with_balances.sum { |data| data[:credit_balance] }
  end

  def balance_sheet
    @as_of_date = params[:as_of_date] ? Date.parse(params[:as_of_date]) : Date.current

    @assets = Account.assets.active.map { |a| [a, a.normal_balance(as_of_date: @as_of_date)] }.reject { |_, b| b.zero? }
    @liabilities = Account.liabilities.active.map { |a| [a, a.normal_balance(as_of_date: @as_of_date)] }.reject { |_, b| b.zero? }
    @equity = Account.equity_accounts.active.map { |a| [a, a.normal_balance(as_of_date: @as_of_date)] }.reject { |_, b| b.zero? }

    @total_assets = @assets.sum { |_, b| b }
    @total_liabilities = @liabilities.sum { |_, b| b }
    @total_equity = @equity.sum { |_, b| b }
  end

  def income_statement
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.current

    # Calculate period balances
    @income_accounts = Account.income_accounts.active.map do |account|
      period_balance = calculate_period_balance(account, @start_date, @end_date)
      [account, period_balance]
    end.reject { |_, b| b.zero? }

    @expense_accounts = Account.expenses.active.map do |account|
      period_balance = calculate_period_balance(account, @start_date, @end_date)
      [account, period_balance]
    end.reject { |_, b| b.zero? }

    @total_income = @income_accounts.sum { |_, b| b }
    @total_expenses = @expense_accounts.sum { |_, b| b }
    @net_income = @total_income - @total_expenses
  end

  private

  def calculate_period_balance(account, start_date, end_date)
    # For income and expense accounts, we want the change during the period
    ending_balance = account.normal_balance(as_of_date: end_date)
    beginning_balance = account.normal_balance(as_of_date: start_date - 1.day)
    ending_balance - beginning_balance
  end
end
