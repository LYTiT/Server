class AddUsernamePrivateToVenueComments < ActiveRecord::Migration
  def change
    add_column :venue_comments, :username_private, :boolean, default: false
  end
end
