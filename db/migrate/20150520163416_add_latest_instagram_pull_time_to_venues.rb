class AddLatestInstagramPullTimeToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :last_instagram_pull_time, :datetime
  end
end
