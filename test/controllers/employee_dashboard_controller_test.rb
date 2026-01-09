require "test_helper"

class EmployeeDashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get employee_dashboard_index_url
    assert_response :success
  end
end
