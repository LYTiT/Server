class RemoveOutdatedColumns < ActiveRecord::Migration
  def change
  	remove_column :users, :notify_location_added_to_groups
  	remove_column :users, :notify_events_added_to_groups
  	remove_column :users, :notify_venue_added_to_groups
  	remove_column :venues, :google_place_reference
  	remove_column :venues, :google_place_rating
  	remove_column :venues, :last_media_comment_url
  	remove_column :venues, :last_media_comment_type
  	remove_column :venues, :start_date
  	remove_column :venues, :end_date
  	remove_column :venues, :user_id 
  end
end
