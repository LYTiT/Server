class AddTimeStampsToFeedUsers < ActiveRecord::Migration
  def change
	add_column(:feed_users, :created_at, :datetime)
	add_column(:feed_users, :updated_at, :datetime)
  end
end
