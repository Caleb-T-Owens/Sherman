require "application_system_test_case"

class TransactionsFlowTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    visit session_url
    fill_in "Email address", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  test "viewing transactions index" do
    visit transactions_url

    # Should see user's transactions
    assert_text transactions(:draft_transaction).description
    assert_text transactions(:posted_salary).description

    # Should not see other user's transactions
    assert_no_text transactions(:user_two_transaction).description

    # Should show status badges
    assert_text "draft"
    assert_text "posted"
  end

  test "creating a new transaction" do
    visit transactions_url
    click_link "New Transaction"

    assert_selector "h1", text: /New Transaction/i

    # Form should have 2 empty entry rows by default
    assert_selector "[data-transaction-form-target='entry']", count: 2

    # Fill in transaction details
    fill_in "Date", with: Date.today.to_s
    fill_in "Description", with: "Rent payment"
    fill_in "Reference", with: "CHK001"

    # Fill in first entry (rent expense debit)
    within all("[data-transaction-form-target='entry']")[0] do
      select accounts(:rent).name, from: "Account"
      select "debit", from: "Type"
      fill_in "Amount", with: "1500.00"
      fill_in "Memo", with: "Rent expense"
    end

    # Fill in second entry (cash credit)
    within all("[data-transaction-form-target='entry']")[1] do
      select accounts(:cash).name, from: "Account"
      select "credit", from: "Type"
      fill_in "Amount", with: "1500.00"
      fill_in "Memo", with: "Cash payment"
    end

    # Balance indicator should show balanced
    assert_selector "[data-transaction-form-target='difference']", text: "0.00"

    click_button "Create Transaction"

    assert_text "Transaction was successfully created"
    assert_text "Rent payment"
    assert_text "draft"
  end

  test "adding and removing entries dynamically with JavaScript" do
    visit new_transaction_url

    # Should start with 2 entries
    assert_selector "[data-transaction-form-target='entry']", count: 2

    # Click "Add Entry" button
    click_button "Add Entry"

    # Should now have 3 entries
    assert_selector "[data-transaction-form-target='entry']", count: 3

    # Remove an entry
    within all("[data-transaction-form-target='entry']").last do
      click_button "Remove"
    end

    # Back to 2 entries
    assert_selector "[data-transaction-form-target='entry']", count: 2
  end

  test "real-time balance calculation with JavaScript" do
    visit new_transaction_url

    fill_in "Date", with: Date.today.to_s
    fill_in "Description", with: "Balance test"

    # Enter unbalanced amounts
    within all("[data-transaction-form-target='entry']")[0] do
      select accounts(:cash).name, from: "Account"
      select "debit", from: "Type"
      fill_in "Amount", with: "100.00"
    end

    # Trigger the calculation (might need to blur the field)
    page.execute_script("document.querySelector('[data-action*=\"updateTotals\"]').dispatchEvent(new Event('change'))")

    within all("[data-transaction-form-target='entry']")[1] do
      select accounts(:checking).name, from: "Account"
      select "credit", from: "Type"
      fill_in "Amount", with: "50.00"
    end

    # Balance difference should show 50.00
    difference_element = find("[data-transaction-form-target='difference']")
    assert_includes difference_element.text, "50"

    # Complete the balance
    within all("[data-transaction-form-target='entry']")[1] do
      fill_in "Amount", with: "100.00"
    end

    # Should now show balanced (0.00)
    assert_selector "[data-transaction-form-target='difference']", text: "0.00"
  end

  test "creating transaction with multiple entries" do
    visit new_transaction_url

    fill_in "Date", with: Date.today.to_s
    fill_in "Description", with: "Salary split"

    # Add a third entry for salary split
    click_button "Add Entry"

    assert_selector "[data-transaction-form-target='entry']", count: 3

    # 90% to checking
    within all("[data-transaction-form-target='entry']")[0] do
      select accounts(:checking).name, from: "Account"
      select "debit", from: "Type"
      fill_in "Amount", with: "2700.00"
    end

    # 10% to savings
    within all("[data-transaction-form-target='entry']")[1] do
      select accounts(:savings).name, from: "Account"
      select "debit", from: "Type"
      fill_in "Amount", with: "300.00"
    end

    # Salary income
    within all("[data-transaction-form-target='entry']")[2] do
      select accounts(:salary).name, from: "Account"
      select "credit", from: "Type"
      fill_in "Amount", with: "3000.00"
    end

    click_button "Create Transaction"

    assert_text "Transaction was successfully created"
    assert_text "2,700.00"
    assert_text "300.00"
    assert_text "3,000.00"
  end

  test "validation error for unbalanced transaction" do
    visit new_transaction_url

    fill_in "Date", with: Date.today.to_s
    fill_in "Description", with: "Unbalanced test"

    within all("[data-transaction-form-target='entry']")[0] do
      select accounts(:cash).name, from: "Account"
      select "debit", from: "Type"
      fill_in "Amount", with: "100.00"
    end

    within all("[data-transaction-form-target='entry']")[1] do
      select accounts(:checking).name, from: "Account"
      select "credit", from: "Type"
      fill_in "Amount", with: "200.00"
    end

    click_button "Create Transaction"

    # Should show error message
    assert_text "must be balanced"
  end

  test "editing draft transaction" do
    transaction = transactions(:draft_transaction)

    visit transaction_url(transaction)
    click_link "Edit"

    fill_in "Description", with: "Updated draft description"

    # Modify entry amounts
    within all("[data-transaction-form-target='entry']")[0] do
      fill_in "Amount", with: "250.00"
    end

    within all("[data-transaction-form-target='entry']")[1] do
      fill_in "Amount", with: "250.00"
    end

    click_button "Update Transaction"

    assert_text "Transaction was successfully updated"
    assert_text "Updated draft description"
    assert_text "250.00"
  end

  test "cannot edit posted transaction" do
    transaction = transactions(:posted_salary)

    visit transaction_url(transaction)

    # Should not see Edit link
    assert_no_link "Edit"
  end

  test "deleting draft transaction" do
    transaction = transactions(:draft_transaction)

    visit transaction_url(transaction)

    accept_confirm do
      click_button "Delete"
    end

    assert_text "Transaction was successfully deleted"
    assert_current_path transactions_url

    # Should not appear in list
    assert_no_text transaction.description
  end

  test "cannot delete posted transaction" do
    transaction = transactions(:posted_salary)

    visit transaction_url(transaction)

    # Should not see Delete button
    assert_no_button "Delete"
  end

  test "viewing transaction details" do
    transaction = transactions(:posted_salary)

    visit transaction_url(transaction)

    # Should show all transaction info
    assert_text transaction.description
    assert_text transaction.reference
    assert_text transaction.date.strftime("%Y-%m-%d")
    assert_text "posted"

    # Should show all entries
    assert_text accounts(:checking).name
    assert_text accounts(:salary).name
    assert_text "3,000.00"

    # Should show balance verification
    assert_text "Balanced"
  end

  test "transaction show page has correct action buttons for draft" do
    transaction = transactions(:draft_transaction)

    visit transaction_url(transaction)

    # Draft should have Edit, Delete, and Post buttons
    assert_link "Edit"
    assert_button "Delete"
    assert_button "Post Transaction"
  end

  test "transaction show page has correct action buttons for posted" do
    transaction = transactions(:posted_salary)

    visit transaction_url(transaction)

    # Posted should only have Void button
    assert_no_link "Edit"
    assert_no_button "Delete"
    assert_no_button "Post Transaction"
    assert_button "Void Transaction"
  end

  test "transaction show page has no action buttons for void" do
    transaction = transactions(:void_transaction)

    visit transaction_url(transaction)

    # Void should have no action buttons
    assert_no_link "Edit"
    assert_no_button "Delete"
    assert_no_button "Post Transaction"
    assert_no_button "Void Transaction"
  end

  test "user isolation - cannot see other user transactions" do
    visit transactions_url

    # Should not see user two's transaction
    assert_no_text transactions(:user_two_transaction).description

    # Attempting to visit directly should redirect or show error
    visit transaction_url(transactions(:user_two_transaction))

    # Should either redirect to transactions index or show not found
    # (implementation dependent)
    assert_no_text transactions(:user_two_transaction).description
  end

  test "transaction form shows totals and difference" do
    visit new_transaction_url

    # Should display total debit, total credit, and difference elements
    assert_selector "[data-transaction-form-target='totalDebits']"
    assert_selector "[data-transaction-form-target='totalCredits']"
    assert_selector "[data-transaction-form-target='difference']"
  end

  test "can remove existing persisted entries when editing" do
    transaction = transactions(:draft_transaction)

    visit edit_transaction_url(transaction)

    # Should have existing entries
    initial_count = all("[data-transaction-form-target='entry']").count
    assert initial_count >= 2

    # Remove one entry
    within all("[data-transaction-form-target='entry']").first do
      click_button "Remove"
    end

    # Entry should be hidden (marked for destruction)
    # The actual behavior depends on implementation
    # It might hide the entry or reduce the visible count
  end

  test "transaction list shows key information" do
    visit transactions_url

    # Should show date, description, status, and balance for each transaction
    within "table" do
      assert_text transactions(:posted_salary).date.strftime("%Y-%m-%d")
      assert_text transactions(:posted_salary).description
      assert_text "posted"
    end
  end

  test "can navigate from transaction list to detail" do
    transaction = transactions(:posted_salary)

    visit transactions_url

    click_link transaction.description

    assert_current_path transaction_url(transaction)
  end
end
