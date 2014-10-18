json.array! @followed_venues do |v|
	json.id v.id
	json.name v.name
	json.created_at v.created_at
  	json.updated_at v.updated_at
  	json.followers_count v.followers.count
end
