json.cache! @tweets do |json|
	json.tweets(@tweets) do |tweet|
		json.lytit_tweet_id Tweet.implicit_id(tweet)
		json.tweet_id Tweet.implicit_twitter_id(tweet)
		json.comment Tweet.implicit_text(tweet)
		json.tweet_image_url_1 Tweet.implicit_image_url_1(tweet)
		json.tweet_image_url_2 Tweet.implicit_image_url_2(tweet)
		json.tweet_image_url_3 Tweet.implicit_image_url_3(tweet)
		json.tweet_created_at Tweet.implicit_timestamp(tweet)
		json.twitter_user_name Tweet.implicit_author_name(tweet)
		json.twitter_user_avatar_url Tweet.implicit_author_avatar(tweet)
		json.twitter_user_id Tweet.implicit_author_id(tweet)
		json.twitter_handle Tweet.implicit_handle(tweet)
	end
end

