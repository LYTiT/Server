class ChangeVenueCommentColumnNames < ActiveRecord::Migration
  def change
  	rename_column :venue_comments, :type, :entry_type
  	rename_column :venue_comments, :venue, :venue_details
  	rename_column :venue_comments, :user, :user_details
  end
end
