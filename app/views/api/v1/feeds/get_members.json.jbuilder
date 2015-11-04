json.array! @users do |user|
	json.id user.id
	json.name user.name
	json.user_phone user.phone_number
	json.num_lists	user.feeds.count
	json.total_pages @users.total_pages
end