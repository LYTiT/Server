class CreateFeedShares < ActiveRecord::Migration
  def change
    create_table :feed_shares do |t|
    	t.references :feed, index: true
    	t.references :venue_comment
    	t.references :user, index: true
    end
  end
end
