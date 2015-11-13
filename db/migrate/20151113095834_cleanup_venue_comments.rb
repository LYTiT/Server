class CleanupVenueComments < ActiveRecord::Migration
  def change
  	remove_column :venue_comments, :username_private, :boolean
  	remove_column :venue_comments, :consider, :integer
  	remove_column :venue_comments, :from_user, :boolean
  	remove_column :venue_comments, :session, :integer
  	remove_column :venue_comments, :is_response, :boolean
  	remove_column :venue_comments, :is_response_accepted, :boolean
  	remove_column :venue_comments, :rejection_reason, :string
  end
end
