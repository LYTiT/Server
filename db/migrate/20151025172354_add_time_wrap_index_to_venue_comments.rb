class AddTimeWrapIndexToVenueComments < ActiveRecord::Migration
  def change
  	add_index "venue_comments", ["time_wrapper"]
  end
end
