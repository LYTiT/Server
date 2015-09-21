class AddTimeStampsToFeedVenues < ActiveRecord::Migration
  def change
  	add_column(:feed_venues, :created_at, :datetime)
	add_column(:feed_venues, :updated_at, :datetime)
  end
end
