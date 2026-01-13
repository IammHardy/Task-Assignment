class Task < ApplicationRecord
  belongs_to :user
  belongs_to :manager, class_name: "User", optional: true

  validates :title, :status, :due_date, presence: true

  enum :status, {
    pending: "pending",
    in_progress: "in_progress",
    completed: "completed"
  }

  after_update_commit :broadcast_stats

private

def broadcast_stats
  broadcast_replace_to "task_stats",
    target: "task-stats",
    partial: "dashboard/task_stats",
    locals: { tasks: Task.all }

  broadcast_replace_to "tasks_table",
    target: "tasks-table",
    partial: "dashboard/tasks_table",
    locals: { tasks: Task.all }
end

end
