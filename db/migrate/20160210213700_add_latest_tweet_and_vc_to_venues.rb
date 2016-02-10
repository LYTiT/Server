class AddLatestTweetAndVcToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :venue_comment_created_at, :datetime
  	add_column :venues, :venue_comment_media_type, :string
	add_column :venues, :venue_comment_content_origin, :string
    add_column :venues, :venue_comment_thirdparty_username, :string
    add_column :venues, :media_type, :string    
    add_column :venues, :image_url_1, :string
    add_column :venues, :image_url_2, :string
	add_column :venues, :image_url_3, :string
	add_column :venues, :video_url_1, :string
	add_column :venues, :video_url_2, :string
	add_column :venues, :video_url_3, :string
	add_column :venues, :lytit_tweet_id, :integer
	add_column :venues, :twitter_id, :integer, :limit => 8
	add_column :venues, :tweet_text, :text
	add_column :venues, :tweet_created_at, :datetime
	add_column :venues, :tweet_author_name, :string
	add_column :venues, :tweet_author_id, :string
	add_column :venues, :tweet_author_avatar_url, :string
	add_column :venues, :tweet_handle, :string
  end
end
