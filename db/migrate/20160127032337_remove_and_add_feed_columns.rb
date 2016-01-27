class RemoveAndAddFeedColumns < ActiveRecord::Migration
  def change
  	remove_column :feeds, :latest_viewed_time, :datetime
  	remove_column :feeds, :new_media_present, :boolean
  	add_column :feeds, :latest_update_time, :datetime
  end
end
