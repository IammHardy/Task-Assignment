class AddAssignedDateToTasks < ActiveRecord::Migration[8.0]
  def change
    # Only add the column if it does NOT exist yet
    add_column :tasks, :assigned_date, :date unless column_exists?(:tasks, :assigned_date)
  end
end
