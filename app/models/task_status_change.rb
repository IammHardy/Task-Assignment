class TaskStatusChange < ApplicationRecord
  belongs_to :task

  validates :to_status, presence: true
end
