require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get transactions_create_url
    assert_response :success
  end
end
