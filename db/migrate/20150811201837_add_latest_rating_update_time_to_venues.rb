class AddLatestRatingUpdateTimeToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :latest_rating_update_time, :datetime
  end
end
