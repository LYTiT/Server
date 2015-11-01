class AddDescriptionToFeeds < ActiveRecord::Migration
  def change
  	add_column :feeds, :description, :text
  end
end
