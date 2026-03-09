class DashboardController < ApplicationController
  before_action :set_current_user
  before_action :set_active_view_and_users
  before_action :set_active_employee, only: [:index, :mark_complete, :undo_mark_complete]
  before_action :set_active_manager, only: [:index, :mark_complete, :undo_mark_complete]

  # ------------------- DASHBOARD -------------------
  def index
    @tasks_to_show = tasks_for_active_view
    @ai_summary = generate_ai_summary(@tasks_to_show) if @active_view.in?(%w[admin manager])
  end

  # ------------------- TASK CREATION -------------------
def create_task
  @task = Task.new(task_params)
  @task.status ||= "pending"

  if @task.save
    # Turbo stream will handle the prepend
  else
    flash.now[:alert] = "Failed to create task: #{@task.errors.full_messages.join(', ')}"
    render turbo_stream: turbo_stream.replace(
      "task-form",
      partial: "tasks/form",
      locals: {
        task: @task,
        employees: (@active_view == "manager" && @active_manager ? @employees.where(manager_id: @active_manager.id) : @employees),
        managers: @managers,
        active_view: @active_view
      }
    )
  end
end
  # ------------------- MARK COMPLETE -------------------
  def mark_complete
    @task = Task.find(params[:id])
    
    # Save previous status for undo
    TaskStatusChange.create(task: @task, from_status: @task.status, to_status: "completed", user_id: @current_user&.id)
    
    @task.update(status: "completed") # can assign string

    reload_tasks_after_action(params[:view], params[:manager_id], params[:employee_id])

    respond_to do |format|
      format.html { redirect_to dashboard_index_path(view: @active_view) }
      format.turbo_stream
    end
  end

  # ------------------- UNDO MARK COMPLETE -------------------
  def undo_mark_complete
    @task = Task.find(params[:id])
    
    # Find last completed change
    change = TaskStatusChange.where(task_id: @task.id, to_status: 'completed').order(created_at: :desc).first
    previous_status = change&.from_status || 'pending'

    if @task.update(status: previous_status)
      # Record undo
      TaskStatusChange.create(task: @task, from_status: 'completed', to_status: previous_status, user_id: @current_user&.id)
      flash[:notice] = "Task status reverted to #{previous_status}."
    else
      flash[:alert] = "Failed to undo task status: #{@task.errors.full_messages.join(', ')}"
    end

    reload_tasks_after_action(params[:view], params[:manager_id], params[:employee_id])

    respond_to do |format|
      format.html { redirect_to dashboard_index_path(view: @active_view) }
      format.turbo_stream
    end
  end

  # ------------------- UPDATE TASK -------------------
  def update_task
    task = Task.find_by(id: params[:id])
    unless task
      flash[:alert] = "Task not found."
      redirect_to dashboard_index_path(view: @active_view) and return
    end

    if @current_user && @current_user.role.in?(%w[manager admin Manager Admin])
      if task.update(task_params)
        flash[:notice] = "Task updated successfully."
        Rails.logger.info "TASK UPDATED: #{task.inspect}"
      else
        flash[:alert] = "Failed to update task: #{task.errors.full_messages.join(', ')}"
        Rails.logger.error "TASK UPDATE FAILED: #{task.inspect}"
      end
    else
      flash[:alert] = "You do not have permission to update this task."
    end

    redirect_to dashboard_index_path(
      view: @active_view,
      manager_id: params[:manager_id],
      employee_id: params[:employee_id]
    )
  end

  # ------------------- ADMIN ACTIONS -------------------
  def create_manager
    @manager = User.new(name: params[:name], email: params[:email], role: "Manager")

    if @manager.save
      flash[:notice] = "Manager created successfully."
    else
      flash[:alert] = "Failed to create manager: #{@manager.errors.full_messages.join(', ')}"
    end

    redirect_to dashboard_index_path(view: "admin")
  end

  def assign_employee
    employee = User.find_by(id: params[:employee_id])
    manager  = User.find_by(id: params[:manager_id])

    if employee && manager
      if employee.update(manager_id: manager.id)
        flash[:notice] = "#{employee.name} assigned to #{manager.name} successfully."
      else
        flash[:alert] = "Failed to assign employee: #{employee.errors.full_messages.join(', ')}"
      end
    else
      flash[:alert] = "Employee or manager not found."
    end

    redirect_to dashboard_index_path(view: "admin")
  end

  private

  # ------------------- HELPERS -------------------
  def set_current_user
    @current_user ||= User.find_by(role: "admin") || User.find_by(role: "Admin") ||
                      User.find_by(role: "manager") || User.find_by(role: "Manager") ||
                      User.first
  end

  def set_active_view_and_users
    @active_view = params[:view]&.downcase || "admin"
    @managers = User.where(role: "Manager")
    @employees = User.where(role: "Employee")
  end

  def set_active_employee
    return unless @active_view == "employee" || action_name.in?(%w[mark_complete undo_mark_complete])
    @active_employee = if params[:employee_id].present?
                         @employees.find_by(id: params[:employee_id])
                       else
                         @employees.first
                       end
  end

  def set_active_manager
    return unless @active_view == "manager" || action_name.in?(%w[mark_complete undo_mark_complete])
    @active_manager = if params[:manager_id].present?
                        @managers.find_by(id: params[:manager_id])
                      else
                        nil
                      end
  end

  # Load tasks for current view
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

  # Only allow these task params
  def task_params
    params.require(:task).permit(:title, :description, :user_id, :assigned_date, :due_date, :status, :priority, files: [])
  end

  # Reload tasks after mark/undo actions
  def reload_tasks_after_action(view_param, manager_id, employee_id)
    @active_view = view_param&.downcase || "admin"
    @employees = User.where(role: "Employee")
    @managers = User.where(role: "Manager")

    case @active_view
    when "employee"
      @active_employee = User.find_by(id: employee_id)
      @tasks_to_show = @active_employee&.tasks&.includes(:user) || Task.none
    when "manager"
      @active_manager = User.find_by(id: manager_id)
      @tasks_to_show = if @active_manager
                         Task.joins(:user).where(users: { manager_id: @active_manager.id })
                       else
                         Task.joins(:user).where(users: { manager_id: @managers.pluck(:id) })
                       end
    else
      @tasks_to_show = Task.includes(:user).all
    end
  end

  # ------------------- AI SUMMARY -------------------
  def generate_ai_summary(tasks)
  return "No tasks yet." if tasks.empty?

  total     = tasks.count
  completed = tasks.count(&:completed_status?)
  pending   = tasks.count(&:pending_status?)
  overdue   = tasks.count(&:overdue_status?)

  suggestions = []

  overdue_tasks = tasks.select(&:overdue_status?)
  suggestions << "⚠ #{overdue_tasks.count} task(s) are overdue!" if overdue_tasks.any?

  employees_pending = tasks.group_by(&:user).transform_values { |t| t.count(&:pending_status?) }

  due_soon = tasks.select do |t|
  t.pending_status? && t.due_date && t.due_date <= Date.today + 1
end

suggestions << "⚠ #{due_soon.count} task(s) due within 24 hours." if due_soon.any?

  max_pending = employees_pending.values.max
  if max_pending && max_pending > 3
    overworked = employees_pending.select { |_, v| v == max_pending }.keys.map(&:name).join(", ")
    suggestions << "Consider reassigning tasks for overworked employee(s): #{overworked}."
  end

  employee_completed = tasks.group_by(&:user).transform_values { |t| t.count(&:completed_status?) }

best = employee_completed.max_by { |_, v| v }
suggestions << "Top performer: #{best[0].name} (#{best[1]} completed tasks)" if best

heavy = employees_pending.select { |_, v| v > 5 }
if heavy.any?
  names = heavy.keys.map(&:name).join(", ")
  suggestions << "⚠ Heavy workload detected for: #{names}"
end

  <<~TEXT.strip
    Total tasks: #{total}
    Completed: #{completed}
    Pending: #{pending}
    Overdue: #{overdue}
    Suggestions: #{suggestions.join(" ") if suggestions.any?}
  TEXT
end
end