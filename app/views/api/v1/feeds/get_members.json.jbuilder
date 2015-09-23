json.array! @users do |user|
	json.id user.id
	json.name user.name
	json.phonenumber user.phone_number
	json.num_lists	user.feeds.count
end