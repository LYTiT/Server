class ModifyFeeds < ActiveRecord::Migration
  def change
  	add_column :feeds, :open, :boolean, :default => :true
  	add_column :feeds, :num_users, :integer, :default => 1
  end
end
