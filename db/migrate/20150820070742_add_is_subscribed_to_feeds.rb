class AddIsSubscribedToFeeds < ActiveRecord::Migration
  def change
  	add_column :feed_users, :is_subscribed, :boolean, :default => :true
  end
end
