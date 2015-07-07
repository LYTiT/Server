class AddDefaultRankValueToVenues < ActiveRecord::Migration
	def up
		change_column :venues, :popularity_rank, :float, :default => 0.0
	end

	def down
		change_column :venues, :popularity_rank, :float, :default => nil
	end
end
