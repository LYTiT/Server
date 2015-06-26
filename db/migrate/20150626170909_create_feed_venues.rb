class CreateFeedVenues < ActiveRecord::Migration
  def change
    create_table :feed_venues do |t|
    	t.references :feed, index: true
    	t.references :venue, index: true
    	t.references :user
    end
  end
end
