class AddColumnsToUsersAndFeeds < ActiveRecord::Migration
  def change
  	add_column(:users, :num_daily_bolts, :integer)
  	add_column(:feeds, :preview_image_url, :string)
  	add_column(:feeds, :cover_image_url, :string)
  end
end
