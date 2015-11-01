class AddInstIdentifierToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :instagram_id, :string
  end
end
