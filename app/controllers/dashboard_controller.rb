# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :load_users_and_roles

  def index
    @task = Task.new
    @employees = User.where(role: "Employee")
    @tasks = Task.includes(:user).all

    ai_service = AiWorkflowService.new(@tasks, User.where(role: "Manager"))
    @ai_summary, @ai_suggestions = ai_service.progress_and_suggestions
  end

  def ai_refresh
    @tasks = Task.includes(:user).all
    ai_service = AiWorkflowService.new(@tasks, User.where(role: "Manager"))
    @ai_summary, @ai_suggestions = ai_service.progress_and_suggestions

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("ai-suggestions", partial: "dashboard/ai_suggestions", locals: { suggestions: @ai_suggestions }) }
      format.html { redirect_to dashboard_index_path, notice: "AI refreshed!" }
    end
  end

  private

  def load_users_and_roles
    @managers = User.where(role: "Manager")
    @employees_all = User.where(role: "Employee")
  end
end
