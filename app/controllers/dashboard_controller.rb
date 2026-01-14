class DashboardController < ApplicationController
  before_action :set_current_user
  before_action :set_active_employee, only: [:index, :mark_complete]

  # ------------------- DASHBOARD -------------------
  def index
    @active_view = params[:view]&.downcase || "admin"

    @managers = User.where(role: "Manager")
    @employees = User.where(role: "Employee")

    # Set tasks for view
    @tasks_to_show = tasks_for_active_view

    # AI summary only for admin/manager
    @ai_summary = generate_ai_summary(@tasks_to_show) if @active_view.in?(%w[admin manager])
  end

  # ------------------- TASK CREATION -------------------
  def create_task
    Task.create!(task_params)
    broadcast_ai_summary
    redirect_to dashboard_index_path(view: params[:view], manager_id: params[:manager_id])
  end

  # ------------------- MARK COMPLETE -------------------
  def mark_complete
    task = Task.find(params[:id])
    if task.user == @active_employee
      task.update!(status: "completed")
    end

    respond_to do |format|
      format.html { redirect_to dashboard_index_path(view: "employee", employee_id: @active_employee.id) }

      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "tasks-table",
          partial: "dashboard/tasks_table",
          locals: {
            tasks_to_show: @active_employee.tasks.includes(:user),
            active_view: "employee",
            active_employee: @active_employee,
            employees: @employees # for forms in table
          }
        )
      end
    end
  end

  # ------------------- UPDATE TASK -------------------
  def update_task
    task = Task.find(params[:id])
    if @current_user.role.in?(["Manager", "Admin"])
      task.update!(task_params)
    end

    respond_to do |format|
      format.html { redirect_to dashboard_index_path(view: @active_view), notice: "Task updated!" }

      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "tasks-table",
          partial: "dashboard/tasks_table",
          locals: {
            tasks_to_show: tasks_for_active_view,
            active_view: @active_view,
            active_employee: @active_employee,
            employees: @employees
          }
        )
      end
    end
  end

  # ------------------- ASSIGN MANAGER -------------------
  def assign_manager
    employee = User.find(params[:employee_id])
    employee.update(manager_id: params[:manager_id])
    redirect_to dashboard_index_path(view: "admin"), notice: "#{employee.name} assigned to manager successfully!"
  end

  # ------------------- HELPERS -------------------
  private

  # Strong params
  def task_params
    params.require(:task).permit(:title, :description, :user_id, :assigned_date, :due_date, :status)
  end

  # Current user (fallback to Admin for demo)
  def set_current_user
    @current_user ||= User.find_by(role: "Admin")
  end

  # Active employee for employee view or mark_complete
  def set_active_employee
    return unless params[:view] == "employee" || action_name == "mark_complete"

    @employees = User.where(role: "Employee")
    @active_employee = if params[:employee_id].present?
                         @employees.find(params[:employee_id])
                       else
                         @employees.first
                       end
  end

  # Tasks depending on view
  def tasks_for_active_view
    case @active_view
    when "admin"
      Task.includes(:user).all
    when "manager"
      manager_id = params[:manager_id] || @current_user.id
      Task.joins(:user).where(users: { manager_id: manager_id })
    when "employee"
      @active_employee.tasks.includes(:user)
    else
      Task.none
    end
  end

  # Broadcast AI summary (optional)
  def broadcast_ai_summary
    tasks = tasks_for_active_view
    ai_summary_text = generate_ai_summary(tasks)
    turbo_stream_action_tag :replace,
                            target: "ai_summary_frame",
                            partial: "dashboard/ai_summary",
                            locals: { ai_summary: ai_summary_text }
  end

  # AI summary generator
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
