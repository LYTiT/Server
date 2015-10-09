class AddDefaultNumLikesCountToFeedVenues < ActiveRecord::Migration
  	def up
		change_column :feed_venues, :num_likes, :integer, :default => 0
	end

	def down
		change_column :feed_venues, :num_likes, :integer, :default => nil
	end
end
