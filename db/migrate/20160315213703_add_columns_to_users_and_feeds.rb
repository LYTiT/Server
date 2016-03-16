class AddColumnsToUsersAndFeeds < ActiveRecord::Migration
  def change
  	add_column :users, :num_bolts, :integer, :default => 0
  	add_column :feeds, :preview_image_url, :string
  	add_column :feeds, :cover_image_url, :string
  end
end
