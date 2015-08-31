class CreateFeedMessages < ActiveRecord::Migration
  def change
    create_table :feed_messages do |t|
    	t.text :message
    	t.references :feed, index: true
    	t.references :user, index: true    	
    	t.timestamps
    end
  end
end
