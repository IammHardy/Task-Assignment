class User < ApplicationRecord
  has_many :tasks
  validates :name, :email, :role, presence: true

  ROLES = ["Manager", "Employee"]
end
