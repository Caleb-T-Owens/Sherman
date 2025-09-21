require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "complete registration and authentication flow" do
    # Navigate to sign up
    visit root_path
    click_link "Sign Up"
    assert_selector "h1", text: "Sign Up"

    # Register a new user
    email = "user_#{SecureRandom.hex(4)}@example.com"
    fill_in "Email address", with: email
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Sign Up"

    # Should be logged in
    assert_text email
    assert_link "Sign Out"

    # Sign out
    click_link "Sign Out"
    assert_selector "h1", text: "Sign In"

    # Sign back in with wrong password
    fill_in "Email address", with: email
    fill_in "Password", with: "wrongpassword"
    click_button "Sign In"
    assert_text "Try another email address or password"

    # Sign in with correct password
    fill_in "Email address", with: email
    fill_in "Password", with: "password123"
    click_button "Sign In"
    assert_text email

    # Sign out again
    click_link "Sign Out"
    assert_selector "h1", text: "Sign In"
  end

  test "registration validation errors" do
    visit new_registration_path

    # Test password too short
    fill_in "Email address", with: "test@example.com"
    fill_in "Password", with: "short"
    fill_in "Password confirmation", with: "short"
    click_button "Sign Up"
    assert_text "Password is too short"

    # Test password mismatch
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "different456"
    click_button "Sign Up"
    assert_text "Password confirmation doesn't match"

    # Test duplicate email (create user first)
    User.create!(email_address: "taken@example.com", password: "password123")
    fill_in "Email address", with: "taken@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Sign Up"
    assert_text "Email address has already been taken"
  end

  test "navigation between authentication pages" do
    # Start at home
    visit root_path
    assert_link "Sign Up"
    assert_link "Sign In"

    # Go to sign in
    click_link "Sign In"
    assert_selector "h1", text: "Sign In"
    assert_link "Sign Up"
    assert_link "Forgot password?"

    # Go to sign up
    click_link "Sign Up"
    assert_selector "h1", text: "Sign Up"
    assert_link "Sign In"

    # Go to password reset
    visit new_session_path
    click_link "Forgot password?"
    assert_selector "h1", text: "Forgot your password?"
  end
end