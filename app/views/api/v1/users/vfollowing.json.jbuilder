json.array! @followed_venues do |v|
	json.id v.id
	json.name v.name
	json.created_at v.created_at
  	json.updated_at v.updated_at
  	json.formatted_address v.address
  	json.latitude v.latitude
 	json.longitude v.longitude
 	json.is_following 1
  	json.followers_count v.followers.count
	json.last_media_comment_url v.last_media_comment_url
	json.last_media_comment_type v.last_media_comment_type
end
