require 'test_helper'

class AdminCompaniesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_companies_index_url
    assert_response :success
  end

end
