require "test_helper"

class RepositoryTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "test@example.com",
      password: "password123"
    )
  end

  test "valid repository with all attributes" do
    repository = Repository.new(
      owner: "octocat",
      repo: "hello-world",
      gh_token: "ghp_test_token_123"
    )
    repository.users << @user
    assert repository.valid?
  end

  test "invalid without owner" do
    repository = Repository.new(
      repo: "hello-world",
      gh_token: "ghp_test_token_123"
    )
    repository.users << @user
    assert_not repository.valid?
    assert_includes repository.errors[:owner], "can't be blank"
  end

  test "invalid without repo" do
    repository = Repository.new(
      owner: "octocat",
      gh_token: "ghp_test_token_123"
    )
    repository.users << @user
    assert_not repository.valid?
    assert_includes repository.errors[:repo], "can't be blank"
  end

  test "invalid without gh_token" do
    repository = Repository.new(
      owner: "octocat",
      repo: "hello-world"
    )
    repository.users << @user
    assert_not repository.valid?
    assert_includes repository.errors[:gh_token], "can't be blank"
  end

  test "invalid without at least one user" do
    repository = Repository.new(
      owner: "octocat",
      repo: "hello-world",
      gh_token: "ghp_test_token_123"
    )
    assert_not repository.valid?
    assert_includes repository.errors[:users], "must have at least one user"
  end

  test "full_name returns owner/repo" do
    repository = Repository.new(
      owner: "rails",
      repo: "rails"
    )
    assert_equal "rails/rails", repository.full_name
  end

  test "gh_token is encrypted" do
    repository = Repository.new(
      owner: "octocat",
      repo: "hello-world",
      gh_token: "ghp_secret_token"
    )
    repository.users << @user
    repository.save!

    # The encrypted attribute should not be stored as plain text
    raw_record = Repository.connection.execute(
      "SELECT gh_token FROM repositories WHERE id = #{repository.id}"
    ).first

    # The database should not contain the plain text token
    refute_equal "ghp_secret_token", raw_record["gh_token"]

    # But accessing through the model should decrypt it
    assert_equal "ghp_secret_token", repository.gh_token
  end

  test "associations work correctly" do
    repository = Repository.create!(
      owner: "octocat",
      repo: "hello-world",
      gh_token: "ghp_test_token_123",
      users: [@user]
    )

    assert_equal 1, repository.users.count
    assert_includes repository.users, @user
    assert_includes @user.repositories, repository
  end

  test "deleting repository deletes user_repositories" do
    repository = Repository.create!(
      owner: "octocat",
      repo: "hello-world",
      gh_token: "ghp_test_token_123",
      users: [@user]
    )

    assert_difference "UserRepository.count", -1 do
      repository.destroy
    end
  end
end