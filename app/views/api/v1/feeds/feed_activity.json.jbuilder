json.activity(@activities) do |activity|
  json.feed_id activity.feed_id
  json.feed_name activity.feed_name
  json.feed_color activity.feed_color
  json.list_creator_id  activity.feed_creator_id

  json.id activity.id
  json.activity_type activity.activity_type
  json.user_id activity.user_id
  json.user_name activity.user_name
  json.user_phone activity.user_phone
  json.fb_id activity.user_facebook_id
  json.fb_name activity.user_facebook_name
  json.created_at activity.created_at
  json.num_chat_participants activity.num_participants
  json.latest_chat_time activity.latest_comment_time

  json.tag_1 activity.tag_1
  json.tag_2 activity.tag_2
  json.tag_3 activity.tag_3
  json.tag_4 activity.tag_4
  json.tag_5 activity.tag_5
  
  json.venue_id activity.venue_id
  json.venue_name activity.venue_name
  json.address activity.venue_address
  json.city activity.venue_city
  json.country activity.venue_country
  json.latitude activity.venue_latitude
  json.longitude activity.venue_longitude
  json.color_rating activity.venue.try(:color_rating)
  json.instagram_location_id activity.venue_instagram_location_id

  json.added_note activity.venue_added_note

  json.venue_comment_id activity.venue_comment_id
  json.venue_comment_created_at activity.venue_comment_created_at
  json.media_type activity.media_type
  json.image_url_1 activity.image_url_1
  json.image_url_2 activity.image_url_2
  json.image_url_3 activity.image_url_3
  json.video_url_1 activity.video_url_1
  json.video_url_2 activity.video_url_2
  json.video_url_3 activity.video_url_3
  json.content_origin activity.venue_comment_content_origin
  json.thirdparty_username activity.venue_comment_thirdparty_username

  json.lytit_tweet_id activity.lytit_tweet_id
  json.tweet_id activity.twitter_id
  json.tweet_created_at activity.tweet_created_at
  json.comment activity.tweet_text
  json.twitter_user_name activity.tweet_author_name
  json.twitter_user_id activity.tweet_author_id
  json.twitter_user_avatar_url activity.tweet_author_avatar_url
  json.twitter_handle activity.tweet_handle
  json.tweet_image_url_1 activity.image_url_1
  json.tweet_image_url_2 activity.image_url_2
  json.tweet_image_url_3 activity.image_url_3

  json.num_likes activity.num_likes
  json.has_liked @user.likes.where("activity_id = ?", activity.id).first.present?
  json.topic activity.message
  json.num_activity_lists activity.num_lists
end