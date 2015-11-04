class AddNumListsToActivity < ActiveRecord::Migration
  def change
  	add_column :activities, :num_lists, :integer, :default => 1
  end
end
