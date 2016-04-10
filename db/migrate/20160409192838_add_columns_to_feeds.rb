class AddColumnsToFeeds < ActiveRecord::Migration
  def change
  	add_column :feeds, :is_private, :boolean, :default => false
  	create_table :feed_join_requests do |t|
    	t.references :user
    	t.references :feed
    	t.boolean :granted
    	t.string :note

    	t.timestamps    	
    end
  end
end
