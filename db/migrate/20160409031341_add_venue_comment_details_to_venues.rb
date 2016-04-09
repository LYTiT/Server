class AddVenueCommentDetailsToVenues < ActiveRecord::Migration
  def change
  	rename_column :venues, :event, :event_details
  	rename_column :venues, :latest_post, :venue_comment_details
  end
end
