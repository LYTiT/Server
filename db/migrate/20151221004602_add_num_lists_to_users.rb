class AddNumListsToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :num_lists, :integer, :default => 0
  end
end
