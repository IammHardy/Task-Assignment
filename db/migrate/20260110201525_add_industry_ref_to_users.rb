class AddIndustryRefToUsers < ActiveRecord::Migration[8.0]
  def change
  add_reference :users, :industry, foreign_key: true
end

end
