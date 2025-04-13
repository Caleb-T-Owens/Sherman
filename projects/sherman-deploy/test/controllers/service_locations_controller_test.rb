require "test_helper"

class ServiceLocationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get service_locations_index_url
    assert_response :success
  end

  test "should get new" do
    get service_locations_new_url
    assert_response :success
  end

  test "should get create" do
    get service_locations_create_url
    assert_response :success
  end

  test "should get edit" do
    get service_locations_edit_url
    assert_response :success
  end

  test "should get update" do
    get service_locations_update_url
    assert_response :success
  end

  test "should get destroy" do
    get service_locations_destroy_url
    assert_response :success
  end
end
