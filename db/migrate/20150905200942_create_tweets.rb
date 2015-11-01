class CreateTweets < ActiveRecord::Migration
  def change
    create_table :tweets do |t|
    	t.integer :twitter_id, :limit => 8
    	t.string :tweet_text
    	t.string :author_id
    	t.string :author_name
    	t.string :author_avatar	
    	t.datetime :timestamp
    	t.references :venue, index: true
    	t.boolean :from_cluster    	
    	t.float :associated_zoomlevel
    	t.integer :cluster_min_venue_id
    	t.float :latitude
    	t.float :longitude

    	t.timestamps
    end
    add_index :tweets, :twitter_id, :unique => true
    add_index :tweets, :latitude
    add_index :tweets, :longitude
  end
end
