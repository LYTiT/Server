class CreateFeedRecommendations < ActiveRecord::Migration
  def change
    create_table :feed_recommendations do |t|
    	t.references :feed, index: true
    	t.string :category
    	t.boolean :active, :default => :true
    	t.boolean :spotlyt, :default => :false
    end
  end
end
