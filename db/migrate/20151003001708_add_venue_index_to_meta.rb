class AddVenueIndexToMeta < ActiveRecord::Migration
  def change
  	add_index "meta_data", ["venue_id"]
  end
end
