class CreateFeedUsers < ActiveRecord::Migration
  def change
    create_table :feed_users do |t|
    	t.references :user, index: true
    	t.references :feed, index: true
    	t.boolean :creator, :default => :false
    end
  end
end
