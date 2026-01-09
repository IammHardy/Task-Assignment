class EmployeeDashboardController < ApplicationController
  before_action :set_employee

  def index
    @tasks = @employee.tasks.order(due_date: :asc)
  end

  private

  def set_employee
    # For demo, pick the first employee (or use session[:user_id] in full app)
    @employee = User.find_by(role: "Employee")
  end
end
