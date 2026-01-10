class AddIndustryToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :industry, :string
  end
end
