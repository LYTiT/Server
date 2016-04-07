class RenameActivityColumns < ActiveRecord::Migration
  def change
  	rename_column :activities, :feed, :feed_details
  	rename_column :activities, :user, :user_details
  	rename_column :activities, :venue, :venue_details
  	rename_column :activities, :venue_comment, :venue_comment_details

  	add_column :activity_comments, :user_details, :json, default: {}, null: false
  	remove_column :activities, :type
  end
end
