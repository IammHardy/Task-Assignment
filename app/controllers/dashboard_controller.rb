# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :load_tasks_and_employees

  def index
    # Needed for the task form
    @task = Task.new

    ai_service = AiWorkflowService.new(@tasks, @employees)
    @ai_summary, @ai_suggestions = ai_service.progress_and_suggestions
  end

  # Called when user clicks "Refresh AI"
  def ai_refresh
    ai_service = AiWorkflowService.new(@tasks, @employees)
    @ai_summary, @ai_suggestions = ai_service.progress_and_suggestions

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_index_path }
    end
  end

  private

  def load_tasks_and_employees
    @tasks = Task.includes(:user)
    @employees = User.where(role: "Employee")
  end
end
