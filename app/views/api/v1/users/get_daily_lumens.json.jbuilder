json.array! @user.lumen_package do |i|
	json.daily_lumens i[0]
	json.daily_color i[1]
end