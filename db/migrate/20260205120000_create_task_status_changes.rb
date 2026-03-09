class CreateTaskStatusChanges < ActiveRecord::Migration[7.0]
  def change
    create_table :task_status_changes do |t|
      t.references :task, null: false, foreign_key: true
      t.string :from_status
      t.string :to_status
      t.integer :user_id

      t.timestamps
    end

    add_index :task_status_changes, [:task_id, :created_at]
  end
end
