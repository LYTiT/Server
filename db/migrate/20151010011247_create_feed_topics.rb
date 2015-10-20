class CreateFeedTopics < ActiveRecord::Migration
  def change
    create_table :feed_topics do |t|
    	t.references :feed, index: true
		t.references :user, index: true
    	t.text :message
    end
  end
end
