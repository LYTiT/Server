json.comments(@comments) do |comment|
    json.venue_id comment.venue_details["id"]
    json.venue_name comment.venue_details["name"]
    json.latitude comment.venue_details["latitude"]
    json.longitude comment.venue_details["longitude"]

    if comment.entry_type == "lytit_post"
        json.content_origin "lytit"
        json.id comment.id
        json.user_id comment.user_details["id"]
        json.user_name comment.user_details["name"]
        json.profile_image_url comment.user_details["profile_image_url"]
        json.media_type comment.lytit_post["media_type"]
        json.media_dimensions comment.lytit_post["media_dimensions"]
        json.image_url_1 comment.lytit_post["image_url_1"]
        json.image_url_2 comment.lytit_post["image_url_2"]
        json.image_url_3 comment.lytit_post["image_url_3"]
        json.video_url_1 comment.lytit_post["video_url_1"]
        json.video_url_2 comment.lytit_post["video_url_2"]
        json.video_url_3 comment.lytit_post["video_url_3"]
        json.created_at comment.lytit_post["created_at"]        
        json.reaction comment.lytit_post["reaction"]
        json.num_enlytened comment.num_enlytened
        json.did_evaluate comment.evaluater_user_ids.keys.include?(@user.id)        
    elsif comment.entry_type == "instagram"
        json.content_origin "instagram"
        json.id comment.id
        json.instagram_id comment.instagram["instagram_id"]
        json.media_type comment.instagram["media_type"]
        json.media_dimensions comment.instagram["media_dimensions"]
        json.image_url_1 comment.instagram["image_url_1"]
        json.image_url_2 comment.instagram["image_url_2"]
        json.image_url_3 comment.instagram["image_url_3"]
        json.video_url_1 comment.instagram["video_url_1"]
        json.video_url_2 comment.instagram["video_url_2"]
        json.video_url_3 comment.instagram["video_url_3"]
        json.created_at comment.instagram["created_at"]         
        json.thirdparty_username comment.instagram["instagram_user"]["name"]
        json.thirdparty_user_id comment.instagram["instagram_user"]["instagram_id"]
        json.profile_image_url comment.instagram["instagram_user"]["profile_image_url"]
    elsif comment.entry_type == "tweet"
        json.content_origin "twitter"
        json.id comment.id
        json.lytit_tweet_id comment.tweet["id"]
        json.tweet_id comment.tweet["twitter_id"]
        json.comment comment.tweet["tweet_text"]
        json.tweet_image_url_1 comment.tweet["image_url_1"]
        json.tweet_image_url_2 comment.tweet["image_url_2"]
        json.tweet_image_url_3 comment.tweet["image_url_3"]
        json.tweet_created_at comment.tweet["created_at"]
        json.twitter_user_name comment.tweet["twitter_user"]["name"]
        json.twitter_user_avatar_url comment.tweet["twitter_user"]["profile_image_url"]
        json.twitter_user_id comment.tweet["twitter_user"]["twitter_id"]
        json.twitter_handle comment.tweet["twitter_user"]["handle"]
    else
        json.id comment.id
        json.event_id comment.event["id"]
        json.event_name comment.event["name"]
        json.event_description comment.event["description"]
        json.event_start_time comment.event["start_time"]
        json.event_end_time comment.event["end_time"]
        json.event_source_url comment.event["source_url"]
        json.event_cover_image_url comment.event["cover_image_url"]
    end

end

