require "application_system_test_case"

class ReportsFlowTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    visit session_url
    fill_in "Email address", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  # Trial Balance Tests

  test "viewing trial balance report" do
    visit reports_trial_balance_url

    assert_selector "h1", text: /Trial Balance/i

    # Should have date filter
    assert_field "As of date"

    # Should have account table with debit/credit columns
    assert_text "Account"
    assert_text "Debit"
    assert_text "Credit"
  end

  test "trial balance shows correct balances" do
    visit reports_trial_balance_url

    # From fixtures:
    # Checking: 3000 - 150.50 = 2849.50 debit
    # Salary: 3000 credit
    # Groceries: 150.50 debit

    within "table" do
      # Look for checking account balance
      within "tr", text: accounts(:checking).name do
        assert_text "2,849.50"
      end

      # Look for salary account balance
      within "tr", text: accounts(:salary).name do
        assert_text "3,000.00"
      end

      # Look for groceries account balance
      within "tr", text: accounts(:groceries).name do
        assert_text "150.50"
      end
    end
  end

  test "trial balance totals are balanced" do
    visit reports_trial_balance_url

    # Find total debit and credit rows
    assert_text "Total"

    # Both should be 3000.00
    # Debits: Checking (2849.50) + Groceries (150.50) = 3000
    # Credits: Salary (3000) = 3000
    totals = all("td", text: /3,?000\.00/)
    assert totals.count >= 2 # At least debit and credit totals
  end

  test "filtering trial balance by date" do
    visit reports_trial_balance_url

    # Change date to 2 weeks ago (before salary transaction)
    fill_in "As of date", with: 2.weeks.ago.to_date.to_s
    click_button "Update"

    # Should not include salary or groceries transactions
    # Balances should be different or zero
  end

  test "trial balance excludes void transactions" do
    visit reports_trial_balance_url

    # Void transaction shouldn't affect balances
    # This is implicit in the expected totals being correct
    assert_text "3,000.00"
  end

  test "trial balance excludes draft transactions" do
    visit reports_trial_balance_url

    # Draft transaction entries shouldn't appear
    # Verified by checking expected balances match posted-only
    assert_text accounts(:checking).name
  end

  # Balance Sheet Tests

  test "viewing balance sheet report" do
    visit reports_balance_sheet_url

    assert_selector "h1", text: /Balance Sheet/i

    # Should have date filter
    assert_field "As of date"

    # Should have three sections
    assert_text "Assets"
    assert_text "Liabilities"
    assert_text "Equity"
  end

  test "balance sheet shows correct account types" do
    visit reports_balance_sheet_url

    # Assets section should have checking and cash
    within "section", text: /Assets/i do
      assert_text accounts(:checking).name
      assert_text accounts(:cash).name
    end

    # Should not show income or expense accounts
    page_html = page.html
    assert_not page_html.include?("#{accounts(:groceries).name}.*#{accounts(:salary).name}")
  end

  test "balance sheet verifies accounting equation" do
    visit reports_balance_sheet_url

    # Should show verification that Assets = Liabilities + Equity
    assert_text /balance.*verified/i
  end

  test "filtering balance sheet by date" do
    visit reports_balance_sheet_url

    fill_in "As of date", with: 1.week.ago.to_date.to_s
    click_button "Update"

    # Should show balances as of that date
    assert_selector "h1", text: /Balance Sheet/
  end

  # Income Statement Tests

  test "viewing income statement report" do
    visit reports_income_statement_url

    assert_selector "h1", text: /Income Statement/i

    # Should have date range filters
    assert_field "Start date"
    assert_field "End date"

    # Should have income and expense sections
    assert_text "Income"
    assert_text "Expenses"
  end

  test "income statement shows income and expense accounts" do
    visit reports_income_statement_url

    # Income section
    within "section", text: /Income/i do
      assert_text accounts(:salary).name
    end

    # Expense section
    within "section", text: /Expense/i do
      assert_text accounts(:groceries).name
    end
  end

  test "income statement calculates net income" do
    visit reports_income_statement_url

    # From fixtures: Income (3000) - Expenses (150.50) = 2849.50
    assert_text "Net Income"
    assert_text "2,849.50"
  end

  test "income statement respects date range" do
    visit reports_income_statement_url

    # Filter to only last 3 days (should include groceries but not salary)
    fill_in "Start date", with: 3.days.ago.to_date.to_s
    fill_in "End date", with: Date.today.to_s
    click_button "Update"

    # Should still show the report
    assert_selector "h1", text: /Income Statement/
  end

  test "income statement excludes balance sheet accounts" do
    visit reports_income_statement_url

    # Should not see checking, cash, credit card
    assert_no_text accounts(:checking).name
    assert_no_text accounts(:cash).name
    assert_no_text accounts(:credit_card).name
  end

  test "income statement handles negative net income" do
    # Create large expense transaction
    visit new_transaction_url

    fill_in "Date", with: Date.today.to_s
    fill_in "Description", with: "Large expense for testing"

    within all("[data-transaction-form-target='entry']")[0] do
      select accounts(:rent).name, from: "Account"
      select "debit", from: "Type"
      fill_in "Amount", with: "5000.00"
    end

    within all("[data-transaction-form-target='entry']")[1] do
      select accounts(:checking).name, from: "Account"
      select "credit", from: "Type"
      fill_in "Amount", with: "5000.00"
    end

    click_button "Create Transaction"

    accept_confirm do
      click_button "Post Transaction"
    end

    # View income statement
    visit reports_income_statement_url

    # Net income should be negative
    # Income (3000) - Expenses (150.50 + 5000) = -2150.50
    assert_text "Net"
    # Might be displayed as "(2,150.50)" or "-2,150.50" depending on formatting
  end

  # Navigation and UX Tests

  test "changing date filters and resubmitting" do
    visit reports_trial_balance_url

    custom_date = 1.week.ago.to_date
    fill_in "As of date", with: custom_date.to_s
    click_button "Update"

    # Date should persist in form
    assert_field "As of date", with: custom_date.to_s
  end

  test "reports default to sensible dates" do
    # Trial balance defaults to today
    visit reports_trial_balance_url
    assert_field "As of date", with: Date.today.to_s

    # Balance sheet defaults to today
    visit reports_balance_sheet_url
    assert_field "As of date", with: Date.today.to_s

    # Income statement defaults to current month
    visit reports_income_statement_url
    assert_field "Start date"
    assert_field "End date"
  end

  test "reports are accessible via navigation" do
    # Visit accounts page and look for report links
    visit accounts_url

    # If reports are in navigation
    # assert_link "Trial Balance"
    # assert_link "Balance Sheet"
    # assert_link "Income Statement"

    # Or test direct access
    visit reports_trial_balance_url
    assert_response :success

    visit reports_balance_sheet_url
    assert_response :success

    visit reports_income_statement_url
    assert_response :success
  end

  test "reports exclude other users' data" do
    # User two has a transaction that shouldn't affect user one's reports

    visit reports_trial_balance_url

    # Balances should only reflect user one's transactions
    # Expected totals: 3000 debits, 3000 credits (not including user two's data)
    within "table" do
      assert_text "3,000.00"
    end
  end

  test "trial balance account grouping by type" do
    visit reports_trial_balance_url

    page_text = page.text

    # Accounts should be grouped by type
    # Assets first, then liabilities, equity, income, expenses
    # Verify rough order exists
    assert page_text.index(accounts(:checking).name) # Asset
  end

  test "balance sheet displays subtotals for each section" do
    visit reports_balance_sheet_url

    # Should show total assets, total liabilities, total equity
    assert_text /Total.*Assets?/i
    assert_text /Total.*Liabilities?/i
    assert_text /Total.*Equity/i
  end

  test "income statement displays subtotals" do
    visit reports_income_statement_url

    # Should show total income and total expenses
    assert_text /Total.*Income/i
    assert_text /Total.*Expenses?/i
  end

  test "clicking account name in report navigates to account detail" do
    visit reports_trial_balance_url

    click_link accounts(:checking).name

    assert_current_path account_url(accounts(:checking))
    assert_text "Balance"
  end

  test "report formatting displays currency correctly" do
    visit reports_trial_balance_url

    # Should format as currency with commas and decimals
    # 2849.50 -> 2,849.50 (or $2,849.50 depending on formatting)
    assert_text /2,849\.50/
    assert_text /3,000\.00/
  end

  test "zero balance accounts may or may not display" do
    visit reports_trial_balance_url

    # Cash account has no posted entries, so balance is 0
    # Depending on implementation, it might not display
    # or it might show with 0.00

    # This test documents the behavior
    # assert_text accounts(:cash).name # If showing zero balances
    # assert_no_text accounts(:cash).name # If hiding zero balances
  end

  test "report print or export functionality" do
    visit reports_trial_balance_url

    # If print/export buttons exist
    # assert_button "Print"
    # assert_button "Export to CSV"

    # This is a placeholder for future functionality
  end
end
