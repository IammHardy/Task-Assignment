# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  before_action :set_task, only: [:edit, :update, :destroy, :complete]


  def edit
    @employees = User.where(role: "Employee")
  end

  # POST /tasks
  def create
    @task = Task.new(task_params)

    if @task.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to dashboard_index_path, notice: "Task created!" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("task-form", partial: "tasks/form", locals: { task: @task, employees: User.where(role: "Employee") }) }
        format.html { render "dashboard/index" }
      end
    end
  end

  # PATCH /tasks/:id
  def update
    if @task.update(task_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to dashboard_index_path, notice: "Task updated!" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("task-form", partial: "tasks/form", locals: { task: @task, employees: User.where(role: "Employee") }) }
        format.html { render "dashboard/index" }
      end
    end
  end

  # DELETE /tasks/:id
  def destroy
    @task.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@task) }
      format.html { redirect_to dashboard_index_path, notice: "Task deleted!" }
    end
  end

  # PATCH /tasks/:id/complete
  def complete
    @task.update(status: "completed")
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_index_path, notice: "Task marked complete!" }
    end
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :user_id, :status, :due_date)
  end
end
