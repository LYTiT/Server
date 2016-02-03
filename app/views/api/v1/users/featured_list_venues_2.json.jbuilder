json.activity(@activities) do |activity|
  json.feed_id Feed.joins(:feed_venues, :feed_users).where("feed_venues.venue_id = ? AND feed_users.user_id = ?", activity["id"], @user.id).order("feed_users.interest_score DESC").first.id
  json.feed_name Feed.joins(:feed_venues, :feed_users).where("feed_venues.venue_id = ? AND feed_users.user_id = ?", activity["id"], @user.id).order("feed_users.interest_score DESC").first.name
  json.feed_color Feed.joins(:feed_venues, :feed_users).where("feed_venues.venue_id = ? AND feed_users.user_id = ?", activity["id"], @user.id).order("feed_users.interest_score DESC").first.feed_color
  json.list_creator_id  nil

  json.id nil
  json.activity_type "featured_list_venue"
  json.user_id nil
  json.user_name nil
  json.user_phone nil
  json.created_at nil
  json.num_chat_participants nil
  json.latest_chat_time nil

  json.tag_1 MetaData.where("venue_id = ?", activity["id"]).order("relevance_score DESC LIMIT 1").meta
  json.tag_2 MetaData.where("venue_id = ?", activity["id"]).order("relevance_score DESC LIMIT 1 OFFSET 1").meta
  json.tag_3 MetaData.where("venue_id = ?", activity["id"]).order("relevance_score DESC LIMIT 1 OFFSET 2").meta
  json.tag_4 MetaData.where("venue_id = ?", activity["id"]).order("relevance_score DESC LIMIT 1 OFFSET 3").meta
  json.tag_5 MetaData.where("venue_id = ?", activity["id"]).order("relevance_score DESC LIMIT 1 OFFSET 4").meta
  
  json.venue_id activity["id"]
  json.venue_name activity["name"]
  json.address activity["address"]
  json.city activity["city"]
  json.country activity["country"]
  json.latitude activity["latitude"]
  json.longitude activity["longitude"]
  json.color_rating activity["color_rating"]
  json.instagram_location_id activity["instagram_location_id"]

  json.added_note nil

  json.venue_comment_id activity["venue_comment_id"]
  json.venue_comment_created_at activity["venue_comment_created_at"]
  json.media_type activity["media_type"]
  json.image_url_1 activity["image_url_1"]
  json.image_url_2 activity["image_url_2"]
  json.image_url_3 activity["image_url_3"]
  json.video_url_1 activity["video_url_1"]
  json.video_url_2 activity["video_url_2"]
  json.video_url_3 activity["video_url_3"]
  json.content_origin activity["venue_comment_content_origin"]
  json.thirdparty_username activity["venue_comment_thirdparty_username"]

  json.lytit_tweet_id activity["tweet_id"]
  json.tweet_id activity["twitter_id"]
  json.tweet_created_at activity["tweet_created_at"]
  json.comment activity["tweet_text"]
  json.twitter_user_name activity["tweet_author_name"]
  json.twitter_user_id activity["tweet_author_id"]
  json.twitter_user_avatar_url activity["tweet_author_avatar"]
  json.twitter_handle activity["tweet_handle"]
  json.tweet_image_url_1 activity["image_url_1"]
  json.tweet_image_url_2 activity["image_url_2"]
  json.tweet_image_url_3 activity["image_url_3"]

  json.num_likes nil
  json.has_liked nil
  json.topic nil
  json.num_activity_lists nil
end