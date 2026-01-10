class AddManagerIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :manager_id, :integer
    add_index :users, :manager_id
  end
end
