class AddNewMediaPresentToFeeds < ActiveRecord::Migration
  def change
  	add_column :feeds, :new_media_present, :boolean, :default => false
  end
end
