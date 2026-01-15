class DashboardController < ApplicationController
  before_action :set_current_user
  before_action :set_active_view_and_users
  before_action :set_active_employee, only: [:index, :mark_complete]
  before_action :set_active_manager, only: [:index]

  # ------------------- DASHBOARD -------------------
  def index
    @tasks_to_show = tasks_for_active_view
    @ai_summary = generate_ai_summary(@tasks_to_show) if @active_view.in?(%w[admin manager])
  end

  # ------------------- TASK CREATION -------------------
  def create_task
    Rails.logger.info "TASK PARAMS: #{task_params.inspect}"

    task = Task.new(task_params)
    task.status ||= "pending"

    if task.save
      Rails.logger.info "TASK CREATED: #{task.inspect}"
      flash[:notice] = "Task created successfully."
    else
      Rails.logger.error "TASK FAILED: #{task.errors.full_messages.join(', ')}"
      flash[:alert] = "Failed to create task: #{task.errors.full_messages.join(', ')}"
    end

    redirect_to dashboard_index_path(view: params[:view], manager_id: params[:manager_id], employee_id: params[:employee_id])
  end

  # ------------------- MARK COMPLETE -------------------
 def mark_complete
  task = Task.find(params[:id])
  task.update!(status: "completed") if @active_employee && task.user == @active_employee

  respond_to do |format|
    format.html { redirect_to dashboard_index_path(view: "employee", employee_id: @active_employee&.id) }
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        "tasks-table",
        partial: "dashboard/tasks_table",
        locals: tasks_table_locals_for_employee
      )
    end
  end
end


  # ------------------- UPDATE TASK -------------------
  def update_task
    task = Task.find_by(id: params[:id])
    unless task
      flash[:alert] = "Task not found."
      redirect_to dashboard_index_path(view: @active_view) and return
    end

    if @current_user.role.in?(%w[Manager Admin])
      if task.update(task_params)
        flash[:notice] = "Task updated!"
        Rails.logger.info "TASK UPDATED: #{task.inspect}"
      else
        flash[:alert] = "Failed to update task: #{task.errors.full_messages.join(', ')}"
        Rails.logger.error "TASK UPDATE FAILED: #{task.inspect}"
      end
    else
      flash[:alert] = "You do not have permission to update this task."
    end

    redirect_to dashboard_index_path(view: @active_view, manager_id: params[:manager_id], employee_id: params[:employee_id])
  end

  # ------------------- ASSIGN MANAGER -------------------
  def assign_manager
    employee = User.find_by(id: params[:employee_id])
    manager  = User.find_by(id: params[:manager_id])

    if employee && manager
      employee.update(manager_id: manager.id)
      flash[:notice] = "#{employee.name} assigned to #{manager.name} successfully!"
    else
      flash[:alert] = "Employee or manager not found."
    end

    redirect_to dashboard_index_path(view: "admin")
  end

  # ------------------- HELPERS -------------------
  private

  def set_current_user
    @current_user ||= User.find_by(role: "Admin")
  end

  def set_active_view_and_users
    @active_view = params[:view]&.downcase || "admin"
    @managers = User.where(role: "Manager")
    @employees = User.where(role: "Employee")
  end

  def set_active_employee
    return unless @active_view == "employee" || action_name == "mark_complete"
    @active_employee = if params[:employee_id].present?
                         @employees.find_by(id: params[:employee_id])
                       else
                         @employees.first
                       end
  end

  def set_active_manager
    return unless @active_view == "manager"
    @active_manager = if params[:manager_id].present?
                        @managers.find_by(id: params[:manager_id])
                      else
                        nil
                      end
  end

  def tasks_for_active_view
    case @active_view
    when "admin"
      Task.includes(:user).all
    when "manager"
      if @active_manager
        Task.joins(:user).where(users: { manager_id: @active_manager.id })
      else
        Task.joins(:user).where(users: { manager_id: @managers.pluck(:id) })
      end
    when "employee"
      @active_employee&.tasks&.includes(:user) || Task.none
    else
      Task.none
    end
  end

  def task_params
    params.require(:task).permit(:title, :description, :user_id, :assigned_date, :due_date, :status)
  end

  def generate_ai_summary(tasks)
    return "No tasks yet." if tasks.empty?

    total = tasks.count
    completed = tasks.count { |t| t.status == "completed" }
    pending = tasks.count { |t| t.status == "pending" }
    overdue = tasks.count { |t| t.status == "overdue" }

    suggestions = []
    overdue_tasks = tasks.select { |t| t.status == "overdue" }
    suggestions << "⚠ #{overdue_tasks.count} task(s) are overdue!" if overdue_tasks.any?

    employees_pending = tasks.group_by(&:user).map { |u, t| [u.name, t.count { |task| task.status == "pending" }] }.to_h
    max_pending = employees_pending.values.max
    if max_pending && max_pending > 3
      overworked = employees_pending.select { |_, v| v == max_pending }.keys.join(", ")
      suggestions << "Consider reassigning tasks for overworked employee(s): #{overworked}."
    end

    <<~TEXT.strip
      Total tasks: #{total}
      Completed: #{completed}
      Pending: #{pending}
      Overdue: #{overdue}
      Suggestions: #{suggestions.join(" ")}
    TEXT
  end
end
