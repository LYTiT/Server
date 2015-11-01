class DropFeedMessages < ActiveRecord::Migration
  def change
  	drop_table :feed_messages
  end
end
