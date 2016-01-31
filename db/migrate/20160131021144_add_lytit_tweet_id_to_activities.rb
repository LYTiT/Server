class AddLytitTweetIdToActivities < ActiveRecord::Migration
  def change
  	add_column :activities, :lytit_tweet_id, :integer
  end
end
