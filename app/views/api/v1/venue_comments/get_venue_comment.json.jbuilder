json.venue_id @venue_comment.venue_details["id"]
json.venue_name @venue_comment.venue_details["name"]
json.latitude @venue_comment.venue_details["latitdue"]
json.longitude @venue_comment.venue_details["longitude"]

if @venue_comment.class.name == "Hash" and comment[:created_at] != nil
    json.tweet_id comment[:id]
    json.comment comment[:text]
    json.tweet_image_url_1 Tweet.implicit_image_content_for_hash(comment, "small")
    json.tweet_image_url_2 Tweet.implicit_image_content_for_hash(comment, "medium")
    json.tweet_image_url_3 Tweet.implicit_image_content_for_hash(comment, "large")
    json.tweet_created_at comment[:created_at]
    json.twitter_user_name comment[:user][:name]
    json.twitter_user_avatar_url comment[:user][:profile_image_url]
    json.twitter_user_id comment[:user][:id]
    json.twitter_handle comment[:user][:screen_name]
elsif @venue_comment.class.name == "Hash" and comment["created_time"] != nil
    json.instagram_id comment["id"]
    json.media_type comment["type"]
    json.image_url_1 comment["images"]["thumbnail"]["url"]
    json.image_url_2 comment["images"]["low_resolution"]["url"]
    json.image_url_3 comment["images"]["standard_resolution"]["url"]
    if comment["type"] == "video"
        json.video_url_1 comment["videos"]["low_bandwidth"]["url"] 
        json.video_url_2 comment["videos"]["low_resolution"]["url"]
        json.video_url_3 comment["images"]["standard_resolution"]["url"]
    end
    json.created_at DateTime.strptime(comment["created_time"],'%s')
    json.content_origin "instagram"
    json.thirdparty_username comment["user"]["username"]
    json.thirdparty_user_id comment["user"]["id"]
    json.profile_image_url comment["user"]["profile_picture"]
elsif @venue_comment.entry_type == "lytit_post"
    json.content_origin "lytit"
    json.id @venue_comment.id
    json.user_id @venue_comment.user_details["id"]
    json.user_name @venue_comment.user_details["name"]
    json.media_type @venue_comment.lytit_post["media_type"]
    json.media_dimensions @venue_comment.lytit_post["media_dimensions"]
    json.image_url_1 @venue_comment.lytit_post["image_url_1"]
    json.image_url_2 @venue_comment.lytit_post["image_url_2"]
    json.image_url_3 @venue_comment.lytit_post["image_url_3"]
    json.video_url_1 @venue_comment.lytit_post["video_url_1"]
    json.video_url_2 @venue_comment.lytit_post["video_url_2"]
    json.video_url_3 @venue_comment.lytit_post["video_url_3"]
    json.created_at @venue_comment.lytit_post["created_at"]            
elsif @venue_comment.entry_type == "instagram"
    json.content_origin "instagram"
    json.id @venue_comment.id
    json.instagram_id @venue_comment.instagram["instagram_id"]
    json.media_type @venue_comment.instagram["media_type"]
    json.media_dimensions @venue_comment.instagram["media_dimensions"]
    json.image_url_1 @venue_comment.instagram["image_url_1"]
    json.image_url_2 @venue_comment.instagram["image_url_2"]
    json.image_url_3 @venue_comment.instagram["image_url_3"]
    json.video_url_1 @venue_comment.instagram["video_url_1"]
    json.video_url_2 @venue_comment.instagram["video_url_2"]
    json.video_url_3 @venue_comment.instagram["video_url_3"]
    json.created_at @venue_comment.instagram["created_at"]         
    json.thirdparty_username @venue_comment.instagram["instagram_user"]["name"]
    json.thirdparty_user_id @venue_comment.instagram["instagram_user"]["instagram_id"]
    json.profile_image_url @venue_comment.instagram["instagram_user"]["profile_image_url"]
elsif @venue_comment.entry_type == "tweet"
    json.content_origin "twitter"
    json.id @venue_comment.id
    json.lytit_tweet_id @venue_comment.tweet["id"]
    json.tweet_id @venue_comment.tweet["twitter_id"]
    json.comment @venue_comment.tweet["tweet_text"]
    json.tweet_image_url_1 @venue_comment.tweet["image_url_1"]
    json.tweet_image_url_2 @venue_comment.tweet["image_url_2"]
    json.tweet_image_url_3 @venue_comment.tweet["image_url_3"]
    json.tweet_created_at @venue_comment.tweet["created_at"]
    json.twitter_user_name @venue_comment.tweet["twitter_user"]["name"]
    json.twitter_user_avatar_url @venue_comment.tweet["twitter_user"]["profile_image_url"]
    json.twitter_user_id @venue_comment.tweet["twitter_user"]["twitter_id"]
    json.twitter_handle @venue_comment.tweet["twitter_user"]["handle"]
else
    json.id @venue_comment.id
    json.event_id @venue_comment.event["id"]
    json.event_name @venue_comment.event["name"]
    json.event_description @venue_comment.event["description"]
    json.event_start_time @venue_comment.event["start_time"]
    json.event_end_time @venue_comment.event["end_time"]
    json.event_source_url @venue_comment.event["source_url"]
    json.event_cover_image_url @venue_comment.event["cover_image_url"]
end