class AddManagerIdToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :manager_id, :integer
  end
end
