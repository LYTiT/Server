class AddLocalTimeCreatedAtToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :local_time_created_at, :string
  end
end
