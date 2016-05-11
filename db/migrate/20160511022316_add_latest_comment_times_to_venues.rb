class AddLatestCommentTimesToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :latest_comment_type_times, :json, default: {"lytit_post" => Time.now-1.day, "instagram" => Time.now-1.day, "tweet" => Time.now-1.day, "event" => Time.now-1.day}, null: false
  end
end
