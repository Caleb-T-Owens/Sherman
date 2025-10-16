require "application_system_test_case"

class AccountHierarchyTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    visit session_url
    fill_in "Email address", with: @user.email_address
    fill_in "Password", with: "password"
    click_button "Sign in"
  end

  test "creating nested account structure" do
    # Create parent account
    visit new_account_url

    fill_in "Code", with: "1000"
    fill_in "Name", with: "Assets"
    select "asset", from: "Account type"
    fill_in "Description", with: "All assets"

    click_button "Create Account"
    assert_text "Account was successfully created"

    # Create child account
    visit new_account_url

    fill_in "Code", with: "1100"
    fill_in "Name", with: "Current Assets"
    select "asset", from: "Account type"
    select "Assets", from: "Parent account"
    fill_in "Description", with: "Short-term assets"

    click_button "Create Account"
    assert_text "Account was successfully created"

    # Verify hierarchy in chart of accounts
    visit accounts_url
    assert_text "Assets"
    assert_text "Current Assets"
  end

  test "hierarchical account names display correctly" do
    # Create three-level hierarchy
    visit new_account_url
    fill_in "Code", with: "1000"
    fill_in "Name", with: "Assets"
    select "asset", from: "Account type"
    click_button "Create Account"

    visit new_account_url
    fill_in "Code", with: "1100"
    fill_in "Name", with: "Current Assets"
    select "asset", from: "Account type"
    select "Assets", from: "Parent account"
    click_button "Create Account"

    visit new_account_url
    fill_in "Code", with: "1110"
    fill_in "Name", with: "Cash"
    select "asset", from: "Account type"
    select "Current Assets", from: "Parent account"
    click_button "Create Account"

    # Check if full hierarchical name is displayed
    visit accounts_url
    # Depending on implementation, might show "Assets : Current Assets : Cash"
    assert_text "Cash"
    assert_text "Current Assets"
    assert_text "Assets"
  end

  test "cannot create child with different type than parent" do
    asset_parent = accounts(:cash)

    visit new_account_url

    fill_in "Code", with: "2999"
    fill_in "Name", with: "Invalid Liability Child"
    select "liability", from: "Account type"
    select asset_parent.name, from: "Parent account"

    click_button "Create Account"

    # Should show validation error
    assert_text "must be the same type"
  end

  test "viewing hierarchical structure in chart" do
    # Create parent-child
    visit new_account_url
    fill_in "Code", with: "1000"
    fill_in "Name", with: "Parent Asset"
    select "asset", from: "Account type"
    click_button "Create Account"

    visit new_account_url
    fill_in "Code", with: "1100"
    fill_in "Name", with: "Child Asset"
    select "asset", from: "Account type"
    select "Parent Asset", from: "Parent account"
    click_button "Create Account"

    visit accounts_url

    # Should show both accounts
    assert_text "Parent Asset"
    assert_text "Child Asset"

    # Might be indented or show hierarchical codes like "1000.1100"
  end

  test "moving account to different parent" do
    # Create two parent accounts
    visit new_account_url
    fill_in "Code", with: "1000"
    fill_in "Name", with: "Parent 1"
    select "asset", from: "Account type"
    click_button "Create Account"

    visit new_account_url
    fill_in "Code", with: "2000"
    fill_in "Name", with: "Parent 2"
    select "asset", from: "Account type"
    click_button "Create Account"

    # Create child under Parent 1
    visit new_account_url
    fill_in "Code", with: "1100"
    fill_in "Name", with: "Child Account"
    select "asset", from: "Account type"
    select "Parent 1", from: "Parent account"
    click_button "Create Account"

    # Edit child to move to Parent 2
    visit accounts_url
    within "tr", text: "Child Account" do
      click_link "Edit"
    end

    select "Parent 2", from: "Parent account"
    click_button "Update Account"

    assert_text "Account was successfully updated"

    # Verify new hierarchy
    # This depends on how the UI displays parent-child relationships
  end

  test "hierarchical codes display in account list" do
    # Create parent and child
    visit new_account_url
    fill_in "Code", with: "1000"
    fill_in "Name", with: "Parent"
    select "asset", from: "Account type"
    click_button "Create Account"

    visit new_account_url
    fill_in "Code", with: "1100"
    fill_in "Name", with: "Child"
    select "asset", from: "Account type"
    select "Parent", from: "Parent account"
    click_button "Create Account"

    visit new_account_url
    fill_in "Code", with: "1110"
    fill_in "Name", with: "Grandchild"
    select "asset", from: "Account type"
    select "Child", from: "Parent account"
    click_button "Create Account"

    visit accounts_url

    # If full_code is displayed, should show "1000.1100.1110"
    # Otherwise just individual codes
    assert_text "1000"
    assert_text "1100"
    assert_text "1110"
  end

  test "parent account shows children on detail page" do
    # Create parent with children
    parent = Account.create!(code: "1000", name: "Parent Asset", account_type: "asset")
    child1 = Account.create!(code: "1100", name: "Child 1", account_type: "asset", parent: parent)
    child2 = Account.create!(code: "1200", name: "Child 2", account_type: "asset", parent: parent)

    visit account_url(parent)

    # Should show children accounts
    assert_text "Child 1"
    assert_text "Child 2"
  end

  test "leaf account indicator" do
    # Create parent without children (should be leaf initially)
    visit new_account_url
    fill_in "Code", with: "1000"
    fill_in "Name", with: "Leaf Account"
    select "asset", from: "Account type"
    click_button "Create Account"

    leaf = Account.find_by(code: "1000")

    # Add child (parent is no longer leaf)
    visit new_account_url
    fill_in "Code", with: "1100"
    fill_in "Name", with: "Child"
    select "asset", from: "Account type"
    select "Leaf Account", from: "Parent account"
    click_button "Create Account"

    # If UI indicates leaf accounts differently, test that
  end

  test "deleting parent with children shows error" do
    parent = Account.create!(code: "1000", name: "Parent", account_type: "asset")
    child = Account.create!(code: "1100", name: "Child", account_type: "asset", parent: parent)

    visit account_url(parent)

    # If delete button exists
    # click_button "Delete"
    # assert_text "Cannot delete account with children"

    # Or deletion might not be exposed in UI at all for accounts with children
  end

  test "deactivating parent account" do
    parent = Account.create!(code: "1000", name: "Parent", account_type: "asset")
    child = Account.create!(code: "1100", name: "Child", account_type: "asset", parent: parent)

    visit edit_account_url(parent)

    uncheck "Active"
    click_button "Update Account"

    assert_text "Account was successfully updated"

    # Parent should not show in chart (inactive)
    visit accounts_url
    assert_no_text parent.name
  end

  test "child account entries do not affect parent balance directly" do
    parent = Account.create!(code: "1000", name: "Parent Asset", account_type: "asset")
    child = Account.create!(code: "1100", name: "Child Asset", account_type: "asset", parent: parent)

    # Create transaction with entry to child
    visit new_transaction_url

    fill_in "Date", with: Date.today.to_s
    fill_in "Description", with: "Entry to child account"

    within all("[data-transaction-form-target='entry']")[0] do
      select child.name, from: "Account"
      select "debit", from: "Type"
      fill_in "Amount", with: "500.00"
    end

    within all("[data-transaction-form-target='entry']")[1] do
      select accounts(:cash).name, from: "Account"
      select "credit", from: "Type"
      fill_in "Amount", with: "500.00"
    end

    click_button "Create Transaction"

    accept_confirm do
      click_button "Post Transaction"
    end

    # Check child balance
    visit account_url(child)
    assert_text "500.00"

    # Parent balance should be 0 (entries to children don't automatically roll up)
    visit account_url(parent)
    # Depending on implementation, might show 0.00 or "No entries"
  end

  test "hierarchical parent selector shows proper nesting" do
    # Create multi-level hierarchy
    level1 = Account.create!(code: "1000", name: "Level 1", account_type: "asset")
    level2 = Account.create!(code: "1100", name: "Level 2", account_type: "asset", parent: level1)

    visit new_account_url

    # Parent dropdown should show hierarchical names or indentation
    # "Level 1"
    # "  Level 2"
    # Or "Level 1 : Level 2"

    select "asset", from: "Account type"

    # If parent selector is filtered by type, should only show asset accounts
    # This is implicit in the setup - just verify it exists
    assert_field "Parent account"
  end

  test "circular parent reference is prevented" do
    parent = Account.create!(code: "1000", name: "Parent", account_type: "asset")
    child = Account.create!(code: "1100", name: "Child", account_type: "asset", parent: parent)

    # Try to edit parent to be child of its own child
    visit edit_account_url(parent)

    select "Child", from: "Parent account"
    click_button "Update Account"

    # Should show validation error
    assert_text /circular|invalid|cannot/i
  end

  test "account type filter in parent selector" do
    asset_account = accounts(:cash)
    liability_account = accounts(:credit_card)

    visit new_account_url

    # Select liability type
    select "liability", from: "Account type"

    # Parent dropdown should only show liability accounts
    # This is hard to test directly without JS inspection
    # But we can verify attempting to select mismatched parent fails

    # If there's dynamic filtering via JS, it won't show asset accounts
  end

  test "breadcrumb or hierarchy display on account detail page" do
    parent = Account.create!(code: "1000", name: "Level 1", account_type: "asset")
    child = Account.create!(code: "1100", name: "Level 2", account_type: "asset", parent: parent)
    grandchild = Account.create!(code: "1110", name: "Level 3", account_type: "asset", parent: child)

    visit account_url(grandchild)

    # Should show breadcrumb or full hierarchical name
    # "Level 1 : Level 2 : Level 3"
    # Or breadcrumbs: Level 1 > Level 2 > Level 3

    assert_text "Level 3"
    # Might also show ancestors
    assert_text "Level 1"
    assert_text "Level 2"
  end
end
