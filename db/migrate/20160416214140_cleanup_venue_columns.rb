class CleanupVenueColumns < ActiveRecord::Migration
  def change
    remove_column :venues, :menu_link, :string
    remove_column :venues, :key, :bigint
    remove_column :venues, :l_sphere, :string
    remove_column :venues, :is_address, :boolean
    remove_column :venues, :has_been_voted_at, :boolean
    remove_column :venues, :popularity_percentile, :float
    remove_column :venues, :user_id, :integer
    remove_column :venues, :is_live, :boolean
    remove_column :venues, :tag_1, :string
    remove_column :venues, :tag_2, :string
    remove_column :venues, :tag_3, :string
    remove_column :venues, :tag_4, :string
    remove_column :venues, :tag_5, :string
    remove_column :venues, :venue_comment_created_at, :datetime
    remove_column :venues, :venue_comment_content_origin, :string
    remove_column :venues, :venue_comment_thirdparty_username, :string
    remove_column :venues, :media_type, :string
    remove_column :venues, :image_url_1, :string
    remove_column :venues, :image_url_2, :string
    remove_column :venues, :image_url_3, :string
    remove_column :venues, :video_url_1, :string
    remove_column :venues, :video_url_2, :string
    remove_column :venues, :video_url_3, :string
    remove_column :venues, :lytit_tweet_id, :integer
    remove_column :venues, :twitter_id, :integer, :limit => 8
    remove_column :venues, :tweet_text, :text
    remove_column :venues, :tweet_created_at, :datetime
    remove_column :venues, :tweet_author_name, :string
    remove_column :venues, :tweet_author_id, :string
    remove_column :venues, :tweet_author_avatar_url, :string
    remove_column :venues, :tweet_handle, :string
    remove_column :venues, :venue_comment_instagram_id, :string
    remove_column :venues, :venue_comment_instagram_user_id, :string
  end
end
