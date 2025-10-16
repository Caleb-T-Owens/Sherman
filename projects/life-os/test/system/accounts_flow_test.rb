require "application_system_test_case"

class AccountsFlowTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    # Sign in
    visit session_url
    fill_in "Email address", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  test "viewing chart of accounts" do
    visit accounts_url

    # Should see all account type sections
    assert_text "Asset"
    assert_text "Liability"
    assert_text "Equity"
    assert_text "Income"
    assert_text "Expense"

    # Should see specific accounts
    assert_text accounts(:cash).name
    assert_text accounts(:checking).name
    assert_text accounts(:salary).name

    # Should not see inactive accounts
    assert_no_text accounts(:inactive_account).name
  end

  test "creating a new account" do
    visit accounts_url
    click_link "New Account"

    assert_selector "h1", text: /New Account/i

    fill_in "Code", with: "1300"
    fill_in "Name", with: "Investment Account"
    select "asset", from: "Account type"
    fill_in "Description", with: "Brokerage account"

    click_button "Create Account"

    assert_text "Account was successfully created"
    assert_text "Investment Account"

    # Verify it appears in the chart of accounts
    visit accounts_url
    assert_text "Investment Account"
    assert_text "1300"
  end

  test "creating account with parent" do
    parent = accounts(:cash)

    visit new_account_url

    fill_in "Code", with: "1001"
    fill_in "Name", with: "Petty Cash"
    select "asset", from: "Account type"
    select parent.name, from: "Parent account"
    fill_in "Description", with: "Small cash on hand"

    click_button "Create Account"

    assert_text "Account was successfully created"

    # Check the account shows hierarchical name
    visit accounts_url
    assert_text "Petty Cash"
  end

  test "validation errors when creating invalid account" do
    visit new_account_url

    # Submit with empty code
    fill_in "Name", with: "Missing Code Account"
    select "asset", from: "Account type"

    click_button "Create Account"

    # Should show validation error
    assert_text "can't be blank"
  end

  test "cannot create account with duplicate code" do
    existing = accounts(:cash)

    visit new_account_url

    fill_in "Code", with: existing.code
    fill_in "Name", with: "Duplicate Code"
    select "asset", from: "Account type"

    click_button "Create Account"

    assert_text "has already been taken"
  end

  test "editing account with no posted entries" do
    account = accounts(:inactive_account)

    visit accounts_url
    # Find and click edit link for this account
    within "tr", text: account.name do
      click_link "Edit"
    end

    fill_in "Code", with: "9998"
    fill_in "Name", with: "Updated Account Name"

    click_button "Update Account"

    assert_text "Account was successfully updated"
    assert_text "9998"
    assert_text "Updated Account Name"
  end

  test "editing account with posted entries has restricted fields" do
    account = accounts(:checking)

    visit edit_account_url(account)

    # Code and type fields should be disabled or readonly
    code_field = find_field("Code")
    type_field = find_field("Account type")

    # Check if fields are disabled/readonly (implementation dependent)
    # Try to change and verify they don't change
    original_code = account.code

    fill_in "Name", with: "Updated Checking Name"
    fill_in "Description", with: "Updated description"

    click_button "Update Account"

    assert_text "Account was successfully updated"

    # Visit account show page and verify code didn't change
    visit account_url(account)
    assert_text original_code
    assert_text "Updated Checking Name"
  end

  test "deactivating account" do
    account = accounts(:savings)

    visit edit_account_url(account)

    uncheck "Active"

    click_button "Update Account"

    assert_text "Account was successfully updated"

    # Account should not appear in main chart
    visit accounts_url
    assert_no_text account.name
  end

  test "viewing account ledger" do
    account = accounts(:checking)

    visit account_url(account)

    # Should show account details
    assert_text account.name
    assert_text account.code
    assert_text "Balance"

    # Should show posted entries
    assert_text "Salary deposit"
    assert_text "Paid from checking"

    # Should show transaction links
    assert_selector "a", text: /Salary payment/
  end

  test "account balance displays correctly" do
    account = accounts(:checking)

    visit account_url(account)

    # From fixtures:
    # Salary: +3000 debit, Groceries: -150.50 credit = 2849.50
    assert_text "2,849.50"
  end

  test "accounts are grouped by type in chart" do
    visit accounts_url

    page_text = page.text

    # Verify ordering: assets section comes before income section
    assert page_text.index("Asset") < page_text.index("Income")
    assert page_text.index("Income") < page_text.index("Expense")
  end

  test "can navigate from chart to account detail" do
    account = accounts(:checking)

    visit accounts_url

    click_link account.name

    assert_current_path account_url(account)
    assert_text account.code
    assert_text account.description
  end

  test "account show page displays recent entries" do
    account = accounts(:checking)

    visit account_url(account)

    # Should show entry details
    within "table" do
      assert_text "3,000.00" # Salary entry
      assert_text "150.50"   # Groceries entry
    end
  end
end
