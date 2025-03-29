require "test_helper"

class FundsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get funds_index_url
    assert_response :success
  end

  test "should get show" do
    get funds_show_url
    assert_response :success
  end

  test "should get new" do
    get funds_new_url
    assert_response :success
  end

  test "should get create" do
    get funds_create_url
    assert_response :success
  end
end
