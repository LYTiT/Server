json.array! @places do |v|
	json.id v.id
	json.name v.name
	json.created_at v.created_at
  	json.updated_at v.updated_at
  	json.formatted_address v.address
  	json.latitude v.latitude
 	json.longitude v.longitude
 	json.is_following @user.vfollowing?(v)
  	json.followers_count v.followers.count
end