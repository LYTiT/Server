class ChangePopularityRankType < ActiveRecord::Migration
  def change
  	change_column :venues, :popularity_rank, :float
  end
end
