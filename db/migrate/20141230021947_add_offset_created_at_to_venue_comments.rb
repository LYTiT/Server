class AddOffsetCreatedAtToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :offset_created_at, :string
  end
end
