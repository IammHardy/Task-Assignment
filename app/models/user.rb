class User < ApplicationRecord
  # Tasks assigned to this user
  has_many :tasks

  # Employees under this manager (if user is a manager)
  has_many :employees, class_name: "User", foreign_key: "manager_id", dependent: :nullify

  # Manager of this user (if user is an employee)
  belongs_to :manager, class_name: "User", optional: true

  # Validations
  validates :name, :email, :role, presence: true

  ROLES = ["Manager", "Employee"]
end
