class AddPopularityRankPopularityPercentileToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :popularity_rank, :integer
  	add_column :venues, :popularity_percentile, :float
  end
end
