json.comments(@comments) do |comment|
	if comment.class.name == "Hash" and comment[:created_at] != nil
		json.tweet_id comment[:id]
		json.comment comment[:text]
		json.tweet_image_url_1 Tweet.append_size_to_tweet_media_url(comment[:media][:first].try([:media_url]), "small")
		json.tweet_image_url_2 Tweet.append_size_to_tweet_media_url(comment[:media][:first].try([:media_url]), "medium")
		json.tweet_image_url_3 Tweet.append_size_to_tweet_media_url(comment[:media][:first].try([:media_url]), "large")
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
		json.id comment.id
		json.lytit_tweet_id comment.tweet["id"]
		json.tweet_id comment.tweet["twitter_id"]
		json.comment comment.tweet["tweet_text"]
		json.tweet_image_url_1 comment.tweet["image_url_1"]
		json.tweet_image_url_2 comment.tweet["image_url_2"]
		json.tweet_image_url_3 comment.tweet["image_url_3"]
		json.tweet_created_at comment.tweet["timestamp"]
		json.twitter_user_name comment.tweet["author_name"]
		json.twitter_user_avatar_url comment.tweet["author_avatar"]
		json.twitter_user_id comment.tweet["author_id"]
		json.twitter_handle comment.tweet["handle"]
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
