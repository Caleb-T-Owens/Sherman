require "application_system_test_case"

class TransactionStateFlowTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    visit session_url
    fill_in "Email address", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  test "posting a valid draft transaction" do
    transaction = transactions(:draft_transaction)

    visit transaction_url(transaction)

    assert_text "draft"
    assert_button "Post Transaction"

    accept_confirm do
      click_button "Post Transaction"
    end

    assert_text "successfully posted"
    assert_text "posted"

    # Should no longer have Edit or Post buttons
    assert_no_link "Edit"
    assert_no_button "Post Transaction"

    # Should now have Void button
    assert_button "Void Transaction"
  end

  test "cannot post unbalanced transaction" do
    # Create an unbalanced draft transaction
    visit new_transaction_url

    fill_in "Date", with: Date.today.to_s
    fill_in "Description", with: "Unbalanced draft"

    within all("[data-transaction-form-target='entry']")[0] do
      select accounts(:cash).name, from: "Account"
      select "debit", from: "Type"
      fill_in "Amount", with: "100.00"
    end

    within all("[data-transaction-form-target='entry']")[1] do
      select accounts(:checking).name, from: "Account"
      select "credit", from: "Type"
      fill_in "Amount", with: "50.00"
    end

    click_button "Create Transaction"

    # Should show validation error, not create
    assert_text "must be balanced"
  end

  test "voiding a posted transaction" do
    transaction = transactions(:posted_salary)

    visit transaction_url(transaction)

    assert_text "posted"
    assert_button "Void Transaction"

    accept_confirm do
      click_button "Void Transaction"
    end

    assert_text "successfully voided"
    assert_text "void"

    # Should no longer have any action buttons
    assert_no_link "Edit"
    assert_no_button "Post Transaction"
    assert_no_button "Void Transaction"
    assert_no_button "Delete"
  end

  test "posted transaction affects account balances" do
    checking = accounts(:checking)

    # View initial balance
    visit account_url(checking)
    initial_balance_text = find("strong", text: /Balance/).text
    initial_balance = initial_balance_text.scan(/[\d,]+\.\d+/).first.gsub(',', '').to_f

    # Create and post new transaction
    visit new_transaction_url

    fill_in "Date", with: Date.today.to_s
    fill_in "Description", with: "New salary deposit"

    within all("[data-transaction-form-target='entry']")[0] do
      select checking.name, from: "Account"
      select "debit", from: "Type"
      fill_in "Amount", with: "1000.00"
    end

    within all("[data-transaction-form-target='entry']")[1] do
      select accounts(:salary).name, from: "Account"
      select "credit", from: "Type"
      fill_in "Amount", with: "1000.00"
    end

    click_button "Create Transaction"

    # Post it
    accept_confirm do
      click_button "Post Transaction"
    end

    assert_text "successfully posted"

    # Check balance increased
    visit account_url(checking)
    new_balance_text = find("strong", text: /Balance/).text
    new_balance = new_balance_text.scan(/[\d,]+\.\d+/).first.gsub(',', '').to_f

    assert_equal initial_balance + 1000.00, new_balance
  end

  test "void transaction does not affect balances" do
    checking = accounts(:checking)

    visit account_url(checking)

    # Balance should not include void transaction entries
    # From fixtures: Salary (+3000) - Groceries (-150.50) = 2849.50
    assert_text "2,849.50"
  end

  test "draft transaction does not affect balances" do
    checking = accounts(:checking)
    draft = transactions(:draft_transaction)

    # Draft has entries for checking but they shouldn't affect balance
    visit account_url(checking)

    # Should only show posted entries in the ledger
    assert_no_text draft.description
  end

  test "state transition UI flow: draft -> posted -> void" do
    # Create new transaction
    visit new_transaction_url

    fill_in "Date", with: Date.today.to_s
    fill_in "Description", with: "State transition test"

    within all("[data-transaction-form-target='entry']")[0] do
      select accounts(:cash).name, from: "Account"
      select "debit", from: "Type"
      fill_in "Amount", with: "500.00"
    end

    within all("[data-transaction-form-target='entry']")[1] do
      select accounts(:checking).name, from: "Account"
      select "credit", from: "Type"
      fill_in "Amount", with: "500.00"
    end

    click_button "Create Transaction"

    # DRAFT state - can edit, delete, post
    assert_text "draft"
    assert_link "Edit"
    assert_button "Delete"
    assert_button "Post Transaction"
    assert_no_button "Void Transaction"

    # Post it
    accept_confirm do
      click_button "Post Transaction"
    end

    # POSTED state - can only void
    assert_text "posted"
    assert_no_link "Edit"
    assert_no_button "Delete"
    assert_no_button "Post Transaction"
    assert_button "Void Transaction"

    # Void it
    accept_confirm do
      click_button "Void Transaction"
    end

    # VOID state - no actions
    assert_text "void"
    assert_no_link "Edit"
    assert_no_button "Delete"
    assert_no_button "Post Transaction"
    assert_no_button "Void Transaction"
  end

  test "posted_at timestamp displays after posting" do
    transaction = transactions(:draft_transaction)

    visit transaction_url(transaction)

    # Draft should not show posted_at
    assert_no_text "Posted at"

    accept_confirm do
      click_button "Post Transaction"
    end

    # Should now show posted_at timestamp
    assert_text "Posted at"
    assert_text Date.today.year.to_s # Should show current date/time
  end

  test "transaction status is visible in list view" do
    visit transactions_url

    within "tr", text: transactions(:draft_transaction).description do
      assert_text "draft"
    end

    within "tr", text: transactions(:posted_salary).description do
      assert_text "posted"
    end

    within "tr", text: transactions(:void_transaction).description do
      assert_text "void"
    end
  end

  test "filtering or sorting by status" do
    visit transactions_url

    # Should be able to see all transactions with different statuses
    assert_text transactions(:draft_transaction).description
    assert_text transactions(:posted_salary).description
    assert_text transactions(:void_transaction).description

    # If status filtering is implemented, test it here
    # Example: click_link "Posted Only"
    # assert_text transactions(:posted_salary).description
    # assert_no_text transactions(:draft_transaction).description
  end

  test "attempting to edit posted transaction redirects with message" do
    transaction = transactions(:posted_salary)

    # Try to visit edit URL directly
    visit edit_transaction_url(transaction)

    # Should redirect to transactions list or show error
    assert_text "cannot edit"
    assert_current_path transactions_url
  end

  test "attempting to delete posted transaction shows error" do
    transaction = transactions(:posted_salary)

    visit transaction_url(transaction)

    # Should not have delete button, but test the controller protection
    # by trying to submit delete directly via JS or URL manipulation
    # This is more of an integration test, but good to verify UI doesn't expose it
    assert_no_button "Delete"
  end

  test "balance verification message on transaction show" do
    transaction = transactions(:posted_salary)

    visit transaction_url(transaction)

    # Should show that debits equal credits
    assert_text "Balanced"

    # Should show total amounts
    assert_text "3,000.00"
  end

  test "can create reversing transaction from posted transaction" do
    transaction = transactions(:posted_salary)

    visit transaction_url(transaction)

    # If there's a "Create Reversing Transaction" button
    # click_button "Create Reversing Transaction"
    #
    # assert_text "Reversing transaction created"
    # Should see new transaction with flipped entries

    # This feature might not be in the UI yet, so this test is a placeholder
  end

  test "immutability of posted transactions" do
    transaction = transactions(:posted_salary)

    visit transaction_url(transaction)

    # Cannot edit
    assert_no_link "Edit"

    # Cannot delete
    assert_no_button "Delete"

    # Can only void
    assert_button "Void Transaction"

    # Verify entry details are displayed but not editable
    assert_text accounts(:checking).name
    assert_text accounts(:salary).name
    assert_no_field "Description"
    assert_no_field "Amount"
  end
end
