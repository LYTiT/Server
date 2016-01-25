class AddInterestScoreToUserFeeds < ActiveRecord::Migration
  def change
  	add_column :feed_users, :interest_score, :float, :default => 0.0
  end
end
