class ChangeVenueInstLocIdType < ActiveRecord::Migration
  def change
  	change_column :venues, :instagram_location_id,  :integer, :limit => 8
  end
end
