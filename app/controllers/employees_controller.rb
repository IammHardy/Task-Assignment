class EmployeesController < ApplicationController
  def index
    # DEMO: Assume employee is logged in
    @employee = User.where(role: "Employee").first
    @tasks = @employee.tasks
  end
end
