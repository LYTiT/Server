class AddTotalViewsToUser < ActiveRecord::Migration
  def change
  	add_column :users, :total_views, :integer, :default => 0
  end
end
