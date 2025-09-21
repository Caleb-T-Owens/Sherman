require "test_helper"

class IssueTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      email_address: "test@example.com",
      password: "password123"
    )

    @repository = Repository.create!(
      owner: "rails",
      repo: "rails",
      gh_token: "test_token",
      users: [@user]
    )
  end

  test "should create issue with valid attributes" do
    issue = @repository.issues.build(
      number: 123,
      title: "Test Issue",
      description: "This is a test issue",
      status: "opened",
      tags: ["bug", "enhancement"]
    )

    assert issue.save
    assert_equal 123, issue.number
    assert_equal "Test Issue", issue.title
    assert_equal "opened", issue.status
    assert_equal ["bug", "enhancement"], issue.tags
  end

  test "should validate presence of required fields" do
    issue = @repository.issues.build

    assert_not issue.save
    assert issue.errors[:number].any?
    assert issue.errors[:title].any?
  end

  test "should enforce unique number per repository" do
    @repository.issues.create!(
      number: 100,
      title: "First Issue",
      status: "opened"
    )

    duplicate = @repository.issues.build(
      number: 100,
      title: "Duplicate Issue",
      status: "opened"
    )

    assert_not duplicate.save
    assert duplicate.errors[:number].any?
  end

  test "should allow same number in different repositories" do
    other_repo = Repository.create!(
      owner: "other",
      repo: "repo",
      gh_token: "token",
      users: [@user]
    )

    issue1 = @repository.issues.create!(
      number: 100,
      title: "Issue in first repo",
      status: "opened"
    )

    issue2 = other_repo.issues.build(
      number: 100,
      title: "Issue in second repo",
      status: "opened"
    )

    assert issue2.save
  end

  test "should handle opened and closed status" do
    open_issue = @repository.issues.create!(
      number: 1,
      title: "Open Issue",
      status: "opened"
    )

    closed_issue = @repository.issues.create!(
      number: 2,
      title: "Closed Issue",
      status: "closed"
    )

    assert open_issue.opened?
    assert_not open_issue.closed?
    assert closed_issue.closed?
    assert_not closed_issue.opened?
  end

  test "should ensure tags is always an array" do
    issue = @repository.issues.create!(
      number: 1,
      title: "Test",
      status: "opened",
      tags: nil
    )

    assert_equal [], issue.tags

    issue.update!(tags: "string")
    assert_equal [], issue.tags

    issue.update!(tags: ["valid", 123, "tag"])
    assert_equal ["valid", "tag"], issue.tags
  end
end
