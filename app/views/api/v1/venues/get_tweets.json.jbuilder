json.tweets(@tweets) do |tweet|
	json.id Tweet.implicit_id(tweet)
	json.twitter_id Tweet.implicit_twitter_id(tweet)
	json.comment Tweet.implicit_tweet_text(tweet)
	json.created_at Tweet.implicit_timestamp(tweet)
	json.user_name Tweet.implicit_author_name(tweet)
	json.media_url Tweet.implicit_author_avatar(tweet)
	json.user_id Tweet.implicit_author_id(tweet)
	json.twitter_handle Tweet.implicit_handle(tweet)
end

json.pagination do 
  json.current_page @tweets.current_page
  json.total_pages @tweets.total_pages
end