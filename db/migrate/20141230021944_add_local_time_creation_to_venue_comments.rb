class AddLocalTimeCreationToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :local_time_creation, :string
  end
end
