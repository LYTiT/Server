json.cache! @view_cache_key, :expires_in => 10.minutes do |json|
	json.comments(@comments) do |comment|
		if comment.class.name == "Hash" and comment[:created_at] != nil
			json.tweet_id comment[:id]
			json.comment comment[:text]
			json.tweet_image_url_1 Tweet.implicit_image_content_for_hash(comment, "small")
			json.tweet_image_url_2 Tweet.implicit_image_content_for_hash(comment, "small")
			json.tweet_image_url_3 Tweet.implicit_image_content_for_hash(comment, "small")
			json.tweet_created_at comment[:created_at]
			json.twitter_user_name comment[:user][:name]
			json.twitter_user_avatar_url comment[:user][:profile_image_url]
			json.twitter_user_id comment[:user][:id]
			json.twitter_handle comment[:user][:screen_name]
		elsif comment.class.name == "Hash" and comment["created_time"] != nil
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
		    json.thirdparty_user_profile_image_url comment["user"]["profile_picture"]
		elsif comment.entry_type == "lytit_post"
			json.content_origin "lytit"
			json.user_id comment.user_details["id"]
			json.user_name comment.user_details["name"]
			json.id comment.lytit_post["id"]
		    json.media_type comment.lytit_post["media_type"]
		    json.media_dimensions comment.lytit_post["media_dimensions"]
		    json.image_url_1 comment.lytit_post["image_url_1"]
		    json.image_url_2 comment.lytit_post["image_url_2"]
		    json.image_url_3 comment.lytit_post["image_url_3"]
		    json.video_url_1 comment.lytit_post["video_url_1"]
		    json.video_url_2 comment.lytit_post["video_url_2"]
		    json.video_url_3 comment.lytit_post["video_url_3"]
		    json.created_at comment.lytit_post["created_at"]		    
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
		    json.thirdparty_user_profile_image_url comment.instagram["instagram_user"]["profile_image_url"]
		elsif comment.entry_type == "tweet"
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
	json.venue_foursuqare_id @venue.foursquare_id
end
