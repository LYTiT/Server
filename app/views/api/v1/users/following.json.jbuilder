json.array! @followed_users do |followed_user|
	json.id followed_user.id
	json.name followed_user.name
	json.email followed_user.email
	json.created_at followed_user.created_at
  	json.updated_at followed_user.updated_at
  	json.is_following 1
end
