json.array! @comments do |comment|
	if comment.class.name == "Hash" and comment[:created_at] != nil
		json.lytit_tweet_id 
		json.tweet_id 
		json.comment 
		json.tweet_image_url_1 
		json.tweet_image_url_2 
		json.tweet_image_url_3 
		json.tweet_created_at 
		json.twitter_user_name 
		json.twitter_user_avatar_url 
		json.twitter_user_id 
		json.twitter_handle
	elsif comment.class.name == "Hash" and comment[:created_time] != nil
		json.id comment.id
	    json.instagram_id comment.instagram_id
	    json.media_type comment.media_type
	    json.image_url_1 comment.image_url_1
	    json.image_url_2 comment.image_url_2
	    json.image_url_3 comment.image_url_3
	    json.video_url_1 comment.video_url_1
	    json.video_url_2 comment.video_url_2
	    json.video_url_3 comment.video_url_3
	    json.created_at comment.time_wrapper
	    json.content_origin "instagram"
	    json.thirdparty_username comment.thirdparty_username
	elsif comment.user_id != nil
		json.id comment.id
	    json.media_type comment.media_type
	    json.media_dimensions comment.media_dimensions
	    json.image_url_1 comment.image_url_1
	    json.image_url_2 comment.image_url_2
	    json.image_url_3 comment.image_url_3
	    json.video_url_1 comment.video_url_1
	    json.video_url_2 comment.video_url_2
	    json.video_url_3 comment.video_url_3
	    json.created_at comment.created_at
	    json.content_origin "lytit"
	elsif comment.instagram_id != nil
		json.id comment.id
	    json.instagram_id comment.instagram_id
	    json.media_type comment.media_type
	    json.image_url_1 comment.image_url_1
	    json.image_url_2 comment.image_url_2
	    json.image_url_3 comment.image_url_3
	    json.video_url_1 comment.video_url_1
	    json.video_url_2 comment.video_url_2
	    json.video_url_3 comment.video_url_3
	    json.created_at comment.time_wrapper
	    json.content_origin "instagram"
	    json.thirdparty_username comment.thirdparty_username
	elsif comment.tweet != {}
		json.lytit_tweet_id 
		json.tweet_id 
		json.comment 
		json.tweet_image_url_1 
		json.tweet_image_url_2 
		json.tweet_image_url_3 
		json.tweet_created_at 
		json.twitter_user_name 
		json.twitter_user_avatar_url 
		json.twitter_user_id 
		json.twitter_handle 
	else
		json.id comment.event["id"]
		json.name comment.event["name"]
		json.description comment.event["description"]
		json.start_time comment.event["start_time"].to_i
		json.end_time comment.event["end_time"].to_i
		json.source_url comment.event["source_url"]
		json.cover_image_url comment.event["cover_image_url"]
	end
end

json.venue_id @venue.id