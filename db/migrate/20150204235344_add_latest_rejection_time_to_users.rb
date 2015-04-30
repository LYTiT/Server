class AddLatestRejectionTimeToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :latest_rejection_time, :datetime
  end
end
