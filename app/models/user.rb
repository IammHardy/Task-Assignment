class User < ApplicationRecord
  belongs_to :industry, optional: true

  # Tasks assigned to this user
  has_many :tasks, foreign_key: "user_id"

  # Employees under this manager
  has_many :employees, class_name: "User", foreign_key: "manager_id", dependent: :nullify

  # Manager of this user
  belongs_to :manager, class_name: "User", optional: true

  # Validations
  validates :name, :email, :role, presence: true

  ROLES = ["Admin", "Manager", "Employee"]
end
