class DashboardController < ApplicationController
  def index
    @tasks = Task.all
    @task = Task.new
    @employees = User.where(role: "Employee")
  end
end

