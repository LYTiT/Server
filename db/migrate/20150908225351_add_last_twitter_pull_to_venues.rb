class AddLastTwitterPullToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :last_twitter_pull_time, :datetime
  end
end
