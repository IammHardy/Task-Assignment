class TasksController < ApplicationController
  before_action :set_task, only: [:update]

  def create
    @task = Task.new(task_params)
    @employees = User.where(role: "Employee")

    if @task.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("tasks-table", partial: "dashboard/task_row", locals: { task: @task }),
            turbo_stream.replace("task-stats", partial: "dashboard/task_stats", locals: { tasks: Task.all }),
            turbo_stream.replace("task-form", partial: "tasks/form", locals: { task: Task.new, employees: @employees }),
            turbo_stream.replace("task-msg", partial: "shared/notice", locals: { message: "Task created successfully!" })
          ]
        end
        format.html { redirect_to dashboard_index_path, notice: "Task created successfully!" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("task-form", partial: "tasks/form", locals: { task: @task, employees: @employees })
        end
        format.html { render :new }
      end
    end
  end

  def update
    @employees = User.where(role: "Employee")
    respond_to do |format|
      if @task.update(task_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("task_#{@task.id}", partial: "tasks/task_row", locals: { task: @task }),
            turbo_stream.replace("task-stats", partial: "dashboard/task_stats", locals: { tasks: Task.all }),
            turbo_stream.replace("task-msg", partial: "shared/notice", locals: { message: "Task updated successfully!" })
          ]
        end
        format.html { redirect_to dashboard_index_path, notice: "Task updated successfully!" }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("task_#{@task.id}", partial: "tasks/task_row", locals: { task: @task })
        end
        format.html { render :edit }
      end
    end
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :status, :due_date, :user_id)
  end
end
