class RemoveOutdatedColumns < ActiveRecord::Migration
  def change
  	remove_column :users, :notify_location_added_to_groups, :boolean
  	remove_column :users, :notify_events_added_to_groups, :boolean
  	remove_column :users, :notify_venue_added_to_groups, :boolean
  	remove_column :venues, :google_place_reference, :string
  	remove_column :venues, :google_place_rating, :float
  	remove_column :venues, :last_media_comment_url, :string
  	remove_column :venues, :last_media_comment_type, :string
  	remove_column :venues, :start_date, :datetime
  	remove_column :venues, :end_date, :datetime
  end
end
