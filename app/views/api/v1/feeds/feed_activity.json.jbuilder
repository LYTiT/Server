json.activity(@activities) do |activity|
  json.id activity.id
  json.created_at activity.created_at
  json.activity_type activity.activity_type

  json.feed_id activity.feed_id
  json.feed_name activity.feed_details["name"]
  json.feed_color activity.feed_details["preview_image_url"]
  json.feed_cover_image_url activity.feed_details["cover_image_url"]
  json.feed_thumbnail_image_url activity.feed_details["color"]
  json.list_creator_id  activity.feed_details["creator_id"]
  json.num_activity_lists activity.num_lists

  json.user_id activity.user_id
  json.user_name activity.user_details["name"]
  json.user_profile_image_url activity.user_details["profile_image_url"]

  json.fb_id activity.user_details["facebook_id"]
  json.fb_name activity.user_details["facebook_name"] 

  json.num_chat_participants activity.num_participants
  json.latest_chat_time activity.latest_comment_time
  
  json.venue_id activity.venue_id
  json.venue_name activity.venue_details["name"]
  json.address activity.venue_details["address"]
  json.city activity.venue_details["city"]
  json.country activity.venue_details["country"]
  json.latitude activity.venue_details["latitude"]
  json.longitude activity.venue_details["longitude"]
  json.added_note activity.feed_venue_details["added_note"]
  
  if activity.activity_type == "added_venue"
    json.num_upvotes activity.feed_venue.num_upvotes
    json.num_comments activity.feed_venue.num_comments
    json.did_upvote activity.feed_venue.upvote_user_ids.include?(@user.id)
    json.feed_venue_id activity.feed_venue.id
  else
    json.num_comments activity.num_comments
  end

  json.tag_1 activity.venue_details["trending_tags"].try(["tag_1"])
  json.tag_2 activity.venue_details["trending_tags"].try(["tag_2"])
  json.tag_3 activity.venue_details["trending_tags"].try(["tag_3"])
  json.tag_4 activity.venue_details["trending_tags"].try(["tag_4"])
  json.tag_5 activity.venue_details["trending_tags"].try(["tag_5"])

  json.topic activity.topic_details["message"]

  if activity.activity_type == "shared_lytit_post"
    json.venue_comment_id activity.venue_comment_id
    json.venue_comment_created_at activity.venue_comment_details["id"]
    json.content_origin "lytit"
    json.media_dimensions activity.venue_comment_details["lytit_post"]["media_dimensions"]
    json.media_type activity.venue_comment_details["lytit_post"]["media_type"]
    json.image_url_1 activity.venue_comment_details["lytit_post"]["image_url_1"]
    json.image_url_2 activity.venue_comment_details["lytit_post"]["image_url_2"]
    json.image_url_3 activity.venue_comment_details["lytit_post"]["image_url_3"]
    json.video_url_1 activity.venue_comment_details["lytit_post"]["video_url_1"]
    json.video_url_2 activity.venue_comment_details["lytit_post"]["video_url_2"]
    json.video_url_3 activity.venue_comment_details["lytit_post"]["video_url_3"]
    json.user_id activity.user_details["id"]
    json.user_name activity.user_details["name"]
    json.profile_image_url activity.user_details["profile_image_url"]
  elsif activity.activity_type == "shared_instagram"
    json.venue_comment_id activity.venue_comment_id
    json.venue_comment_created_at activity.venue_comment_details["id"]
    json.content_origin activity.venue_comment_details["entry_type"]
    json.media_dimensions activity.venue_comment_details["instagram"]["media_dimensions"]
    json.media_type activity.venue_comment_details["instagram"]["media_type"]
    json.image_url_1 activity.venue_comment_details["instagram"]["image_url_1"]
    json.image_url_2 activity.venue_comment_details["instagram"]["image_url_2"]
    json.image_url_3 activity.venue_comment_details["instagram"]["image_url_3"]
    json.video_url_1 activity.venue_comment_details["instagram"]["video_url_1"]
    json.video_url_2 activity.venue_comment_details["instagram"]["video_url_2"]
    json.video_url_3 activity.venue_comment_details["instagram"]["video_url_3"]
    json.thirdparty_username activity.venue_comment_details["instagram"]["instagram_user"]["name"]
    json.profile_image_url activity.venue_comment_details["instagram"]["instagram_user"]["profile_image_url"]
  elsif activity.activity_type == "shared_tweet"
    json.venue_comment_id activity.venue_comment_details["id"]
    json.lytit_tweet_id activity.venue_comment_details["tweet"]["id"]
    json.tweet_id activity.venue_comment_details["tweet"]["twitter_id"]
    json.comment activity.venue_comment_details["tweet"]["tweet_text"]
    json.tweet_image_url_1 activity.venue_comment_details["tweet"]["image_url_1"]
    json.tweet_image_url_2 activity.venue_comment_details["tweet"]["image_url_2"]
    json.tweet_image_url_3 activity.venue_comment_details["tweet"]["image_url_3"]
    json.tweet_created_at activity.venue_comment_details["tweet"]["created_at"]
    json.twitter_user_name activity.venue_comment_details["tweet"]["twitter_user"]["name"]
    json.twitter_user_avatar_url activity.venue_comment_details["tweet"]["twitter_user"]["profile_image_url"]
    json.twitter_user_id activity.venue_comment_details["tweet"]["twitter_user"]["twitter_id"]
    json.twitter_handle activity.venue_comment_details["tweet"]["twitter_user"]["handle"]
  else
    if activity.activity_type == "shared_event"
      json.venue_comment_id activity.venue_comment_details["id"]
      json.event_id activity.venue_comment_details["event"]["id"]
      json.event_name activity.venue_comment_details["event"]["name"]
      json.event_description activity.venue_comment_details["event"]["description"]
      json.event_start_time activity.venue_comment_details["event"]["start_time"]
      json.event_end_time activity.venue_comment_details["event"]["end_time"]
      json.event_source_url activity.venue_comment_details["event"]["source_url"]
      json.event_cover_image_url activity.venue_comment_details["event"]["cover_image_url"]
    end
  end

end