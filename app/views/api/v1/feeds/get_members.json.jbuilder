json.array! @users do |user|
	json.id user.id
	json.name user.name
	json.phone_number user.phone_number
	json.num_lists	user.feeds.count
	json.num_stars user.num_likes
end