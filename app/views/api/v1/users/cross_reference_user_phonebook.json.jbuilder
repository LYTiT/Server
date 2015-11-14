json.array! @users do |user|
	json.id user.id
	json.name user.name
	json.user_phone user.phone_number
	json.num_lists	user.feed_users.count
	json.num_start user.num_stars
end