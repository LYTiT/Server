class AddColumnsToVenueCommentsAndActivities < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :lytit_post, :json, default: {}, null: false
  	add_column :venue_comments, :instagram, :json, default: {}, null: false
  	add_column :venue_comments, :user, :json, default: {}, null: false
  	add_column :venue_comments, :venue, :json, default: {}, null: false
  	add_column :venue_comments, :type, :string

  	add_column :activities, :venue_comment, :json, default: {}, null: false
  	add_column :activities, :event, :json, default: {}, null: false
  	add_column :activities, :venue, :json, default: {}, null: false
  	add_column :activities, :feed, :json, default: {}, null: false
  	add_column :activities, :user, :json, default: {}, null: false
  	add_column :activities, :feed_user, :json, default: {}, null: false
  	add_column :activities, :feed_venue, :json, default: {}, null: false
  	add_column :activities, :type, :string
  end
end
