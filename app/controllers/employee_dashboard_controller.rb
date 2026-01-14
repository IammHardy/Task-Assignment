class EmployeeDashboardController < ApplicationController
  before_action :set_employee

 # EmployeeDashboardController
def index
  @tasks_to_show = Task.where(user_id: current_user.id)
  @current_user = current_user
end


  private

  def set_employee
    # For demo, pick the first employee
    @employee = User.find_by(role: "Employee")
  end
end
