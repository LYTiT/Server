class CreateActivityFeeds < ActiveRecord::Migration
  def change
    create_table :activity_feeds do |t|
    	t.references :activity, index: true
    	t.references :feed, index: true
    end
  end
end
