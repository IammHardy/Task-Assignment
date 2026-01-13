class DashboardController < ApplicationController
  before_action :set_current_user

  def index
    @active_view = params[:view]&.downcase || "admin"

    @managers = User.where(role: "Manager")
    @employees = User.where(role: "Employee")

    

    case @active_view
    when "admin"
      @tasks_to_show = Task.includes(:user).all
    when "manager"
      if params[:manager_id].present?
        @active_manager = @managers.find(params[:manager_id])
        @employees_to_show = @employees.where(manager_id: @active_manager.id)
        @tasks_to_show = Task.joins(:user).where(users: { manager_id: @active_manager.id })
      else
        @tasks_to_show = Task.joins(:user).where(users: { manager_id: @managers.pluck(:id) })
        @employees_to_show = @employees
      end
    when "employee"
      if params[:employee_id].present?
        @active_employee = @employees.find(params[:employee_id])
        @tasks_to_show = Task.where(user_id: @active_employee.id).includes(:user, :manager)
      else
        @tasks_to_show = Task.includes(:user).where(user_id: @employees.pluck(:id))
      end
    end
  end

 def mark_complete
    @task = Task.find(params[:id])
    @task.update(status: "completed")

    respond_to do |format|
      format.html { redirect_back(fallback_location: dashboard_index_path) }
      format.turbo_stream # will render mark_complete.turbo_stream.erb
    end
  end
  def create_task
    Task.create!(
      title: task_params[:title],
      description: task_params[:description],
      user_id: task_params[:user_id],
      assigned_date: task_params[:assigned_date],
      due_date: task_params[:due_date],
      status: "pending"
    )
    redirect_to dashboard_index_path(view: params[:view], manager_id: params[:manager_id])
  end

  def assign_manager
  employee = User.find(params[:employee_id])
  employee.update(manager_id: params[:manager_id])

  redirect_to dashboard_index_path(view: "admin"), notice: "#{employee.name} assigned to manager successfully!"
end


  private

  def task_params
    params.require(:task).permit(:title, :description, :user_id, :assigned_date, :due_date)
  end

  def set_current_user
    @current_user ||= User.find_by(role: "Admin") # fallback for demo
  end
end
