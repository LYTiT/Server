json.activity(@activities) do |activity|
  json.feed_id activity["list_id"]
  json.feed_name activity["list_name"]
  json.feed_color activity["list_color"]
  json.list_creator_id  nil

  json.id nil
  json.activity_type "featured list venue"
  json.user_id nil
  json.user_name nil
  json.user_phone nil
  json.created_at nil
  json.num_chat_participants nil
  json.latest_chat_time nil

  json.tag_1 activity["tag_1"]
  json.tag_2 activity["tag_2"]
  json.tag_3 activity["tag_3"]
  json.tag_4 activity["tag_4"]
  json.tag_5 activity["tag_5"]
  
  json.venue_id activity["venue_id"]
  json.venue_name activity["venue_name"]
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
  json.tweet_image_url_1 activity["tweet_image_url_1"]
  json.tweet_image_url_2 activity["tweet_image_url_1"]
  json.tweet_image_url_3 activity["tweet_image_url_1"]

  json.num_likes nil
  json.has_liked nil
  json.topic nil
  json.num_activity_lists nil
end