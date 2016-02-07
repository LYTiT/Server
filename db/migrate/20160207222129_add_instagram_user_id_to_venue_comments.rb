class AddInstagramUserIdToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :instagram_user_id, :integer, :limit => 8
  end
end
