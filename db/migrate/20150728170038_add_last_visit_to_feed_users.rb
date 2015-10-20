class AddLastVisitToFeedUsers < ActiveRecord::Migration
  def change
  	add_column :feed_users, :last_visit, :datetime
  	add_column :feeds, :latest_content_time, :datetime
  end
end
