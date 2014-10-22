class AddLumenPercentileToUsers < ActiveRecord::Migration
  def change
    add_column :users, :lumen_percentile, :float
  end
end
