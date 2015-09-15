json.array! @tweets do |tweet|
	json.id tweet.id
	json.twitter_id tweet.twitter_id
	json.comment tweet.tweet_text
	json.created_at tweet.timestamp
	json.user_name tweet.author_name
	json.media_url tweet.author_avatar
	json.user_id tweet.author_id
end

json.pagination do 
  json.current_page @tweets.current_page
  json.total_pages @tweets.total_pages
end