json.array! @followed_venues do |v|
	json.id v.id
	json.name v.name
	json.created_at v.created_at
  	json.updated_at v.updated_at
  	json.formatted_address v.address
  	json.latitude v.latitude
 	json.longitude v.longitude
  	json.followers_count v.followers.count
end
