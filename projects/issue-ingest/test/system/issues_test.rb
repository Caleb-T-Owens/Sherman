require "application_system_test_case"

class IssuesTest < ApplicationSystemTestCase
  setup do
    # Create a test user
    @user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    # Create a test repository
    @repository = Repository.create!(
      owner: "rails",
      repo: "rails",
      gh_token: "test_token",
      users: [@user]
    )

    # Login
    visit new_session_url
    fill_in "Email address", with: @user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  test "viewing repository issues page" do
    visit repository_issues_url(@repository)

    assert_selector "h1", text: "rails/rails - Issues"
    assert_text "No issues synced yet for this repository"
    assert_selector "button", text: "Sync Issues from GitHub"
  end

  test "issues page shows sync button when no issues exist" do
    visit repository_issues_url(@repository)

    assert_selector "div.card" do
      assert_text "No issues synced yet"
      assert_selector "button", text: "Sync Issues from GitHub"
    end
  end

  test "issues page displays open and closed issues" do
    # Create some test issues
    @repository.issues.create!(
      number: 1,
      title: "Bug: Something is broken",
      description: "This is a bug description",
      status: "opened",
      tags: ["bug", "high-priority"]
    )

    @repository.issues.create!(
      number: 2,
      title: "Feature: Add new functionality",
      description: "This is a feature request",
      status: "closed",
      tags: ["enhancement"]
    )

    visit repository_issues_url(@repository)

    # Check stats
    assert_text "1 Open"
    assert_text "1 Closed"
    assert_text "2 Total"

    # Check open issues section
    assert_selector "h2", text: "Open Issues"
    assert_text "#1 - Bug: Something is broken"
    assert_selector "span.tag", text: "bug"
    assert_selector "span.tag", text: "high-priority"

    # Check closed issues section
    assert_selector "h2", text: "Closed Issues"
    assert_text "#2 - Feature: Add new functionality"
    assert_selector "span.tag", text: "enhancement"
  end

  test "repository show page has issues section with links" do
    visit repository_url(@repository)

    assert_selector "h3", text: "Issues"
    assert_text "No issues synced yet"
    assert_link "View Issues"
    assert_selector "button", text: "Sync Issues from GitHub"
  end

  test "clicking view issues navigates to issues page" do
    visit repository_url(@repository)
    click_link "View Issues"

    assert_current_path repository_issues_path(@repository)
    assert_selector "h1", text: "rails/rails - Issues"
  end
end
