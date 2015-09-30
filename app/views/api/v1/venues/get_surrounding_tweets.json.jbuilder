json.tweets(@tweets) do |tweet|
	json.id nil
	json.twitter_id tweet.id
	json.comment tweet.text
	json.image_url_1 tweet.media.first.media_url+":small"
	json.image_url_2 tweet.media.first.media_url+":medium"
	json.image_url_3 tweet.media.first.media_url+":large"	
	json.created_at tweet.created_at
	json.user_name tweet.user.name
	json.media_url tweet.user.profile_image_url.to_s
	json.user_id tweet.user.id
	json.twitter_handle tweet.user.screen_name
end

json.pagination do 
  json.current_page @tweets.current_page
  json.total_pages @tweets.total_pages
end