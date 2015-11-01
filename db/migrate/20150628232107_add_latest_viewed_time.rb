class AddLatestViewedTime < ActiveRecord::Migration
  def change
  	add_column :feeds, :latest_viewed_time, :datetime
  end
end
