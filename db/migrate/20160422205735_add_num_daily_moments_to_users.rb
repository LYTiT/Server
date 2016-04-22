class AddNumDailyMomentsToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :num_daily_moments, :integer
  end
end
