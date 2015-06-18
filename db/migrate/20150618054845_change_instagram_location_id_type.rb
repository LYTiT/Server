class ChangeInstagramLocationIdType < ActiveRecord::Migration
	def change
		change_column :instagram_location_id_lookups, :instagram_location_id, 'integer USING CAST(instagram_location_id AS integer)'
	end
end
