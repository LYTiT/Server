class AddIndexToVenuesOnEventId < ActiveRecord::Migration
  def change
  	add_index "venues", ["event_id"]
  end
end
