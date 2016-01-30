class AddColumnsToActivities2 < ActiveRecord::Migration
  def change
  	add_column :activities, :feed_name, :string
  	add_column :activities, :feed_color, :string
    add_column :activities, :feed_creator_id, :integer
  	add_column :activities, :user_name, :string
  	add_column :activities, :user_phone, :string
  	add_column :activities, :venue_instagram_location_id, :integer
  	add_column :activities, :venue_latitude, :float
  	add_column :activities, :venue_longitude, :float
  	add_column :activities, :venue_name, :string
  	add_column :activities, :venue_address, :string
  	add_column :activities, :venue_city, :string
  	add_column :activities, :venue_state, :string
  	add_column :activities, :venue_country, :string
  	add_column :activities, :venue_added_note, :text
  	add_column :activities, :venue_comment_created_at, :datetime
  	add_column :activities, :venue_comment_media_type, :string
  	add_column :activities, :venue_comment_content_origin, :string
  	add_column :activities, :venue_comment_thirdparty_username, :string
  	add_column :activities, :image_url_1, :string
  	add_column :activities, :image_url_2, :string
  	add_column :activities, :image_url_3, :string
  	add_column :activities, :video_url_1, :string
  	add_column :activities, :video_url_2, :string
  	add_column :activities, :video_url_3, :string
    add_column :activities, :tag_1, :string
    add_column :activities, :tag_2, :string
    add_column :activities, :tag_3, :string
    add_column :activities, :tag_4, :string
    add_column :activities, :tag_5, :string
  	add_column :activities, :twitter_id, :integer, :limit => 8
  	add_column :activities, :tweet_text, :text
  	add_column :activities, :tweet_created_at, :datetime
  	add_column :activities, :tweet_author_name, :string
  	add_column :activities, :tweet_author_id, :string
  	add_column :activities, :tweet_author_avatar_url, :string
  	add_column :activities, :tweet_handle, :string
  end
end
