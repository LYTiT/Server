class AddFromUserToVenueComment < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :from_user, :boolean, :default => false
  end
end
