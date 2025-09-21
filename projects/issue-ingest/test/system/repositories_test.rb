require "application_system_test_case"

class RepositoriesTest < ApplicationSystemTestCase
  test "complete repository CRUD operations" do
    # Create and sign in user
    user = User.create!(
      email_address: "repo_test@example.com",
      password: "password123"
    )

    visit new_session_path
    fill_in "Email address", with: "repo_test@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"

    # Navigate to repositories from home
    assert_text "repo_test@example.com"
    click_link "My Repositories"
    assert_selector "h1", text: "My Repositories"
    assert_text "You haven't added any repositories yet"

    # CREATE - Add a new repository
    click_link "Add your first repository"
    assert_selector "h1", text: "Add Repository"

    fill_in "Repository Owner", with: "octocat"
    fill_in "Repository Name", with: "hello-world"
    fill_in "GitHub Personal Access Token", with: "ghp_test_token_12345"
    click_button "Add Repository"

    # READ - View the created repository
    assert_selector "h1", text: "octocat/hello-world"
    assert_text "Repository was successfully created"
    assert_text "✓ Configured"
    assert_text "repo_test@example.com"

    # UPDATE - Edit the repository
    click_link "Edit"
    assert_selector "h1", text: "Edit Repository"
    fill_in "Repository Owner", with: "github"
    fill_in "Repository Name", with: "docs"
    click_button "Update Repository"

    assert_selector "h1", text: "github/docs"
    assert_text "Repository was successfully updated"

    # View index with the repository
    click_link "Back to Repositories"
    assert_selector "h1", text: "My Repositories"
    assert_text "github/docs"

    # Add a second repository
    click_link "Add Repository"
    fill_in "Repository Owner", with: "rails"
    fill_in "Repository Name", with: "rails"
    fill_in "GitHub Personal Access Token", with: "ghp_another_token"
    click_button "Add Repository"

    visit repositories_path
    assert_text "github/docs"
    assert_text "rails/rails"

    # DELETE - Remove a repository
    within("div.card", text: "github/docs") do
      accept_confirm "Are you sure?" do
        click_link "Delete"
      end
    end

    assert_text "Repository was successfully deleted"
    assert_no_text "github/docs"
    assert_text "rails/rails"
  end

  test "navigation between repository pages" do
    # Create user with a repository
    user = User.create!(
      email_address: "nav@example.com",
      password: "password123"
    )
    repo = Repository.create!(
      owner: "existing",
      repo: "repository",
      gh_token: "ghp_existing_token",
      users: [user]
    )

    visit new_session_path
    fill_in "Email address", with: "nav@example.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"

    # Test navigation flow
    click_link "My Repositories"
    assert_current_path repositories_path

    click_link "Add Repository"
    assert_current_path new_repository_path

    click_link "Cancel"
    assert_current_path repositories_path

    click_link "existing/repository"
    assert_selector "h1", text: "existing/repository"

    click_link "Edit"
    assert_current_path edit_repository_path(repo)

    click_link "Cancel"
    assert_selector "h1", text: "existing/repository"

    click_link "Back to Repositories"
    assert_current_path repositories_path
  end
end