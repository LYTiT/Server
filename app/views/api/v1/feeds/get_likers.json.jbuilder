json.users(@likers) do |user|
	json.id user.id
	json.name user.name
	json.user_phone user.phone_number
	json.num_lists user.num_lists
end