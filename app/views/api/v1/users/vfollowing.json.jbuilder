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
  	json.media_url v.last_image.media_url
  	json.media_type v.last_image.media_type
end
