class ModifyLookupInstIdType < ActiveRecord::Migration
  def change
  	change_column :feeds, :in_spotlyt, :boolean, default: true
  	change_column :instagram_location_id_lookups, :instagram_location_id,  :integer, :limit => 8
  end
end
