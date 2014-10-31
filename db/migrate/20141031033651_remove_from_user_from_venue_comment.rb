class RemoveFromUserFromVenueComment < ActiveRecord::Migration
  def change
  	remove_column :venue_comments, :from_user, :integer
  end
end
