class AddLatestEventIdToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :event_id, :integer
  end
end
