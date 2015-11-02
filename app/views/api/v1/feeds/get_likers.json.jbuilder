json.users(@users) do |user|
	json.id user.id
	json.name user.name
	json.user_phone user.phone_number
end