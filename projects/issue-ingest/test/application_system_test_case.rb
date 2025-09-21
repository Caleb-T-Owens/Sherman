require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Helper method to sign in a user in system tests
  def sign_in_as(user)
    visit new_session_path
    fill_in "Email address", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  # Helper to create and sign in a test user
  def sign_in_test_user(email: "test@example.com", password: "password123")
    user = User.create!(
      email_address: email,
      password: password
    )
    sign_in_as(user)
    user
  end
end
