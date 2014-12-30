class AddLocalTimeOffsetToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :local_time_offset, :integer
  end
end
