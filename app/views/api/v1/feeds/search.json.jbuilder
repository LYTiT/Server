json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.creator feed.user
	json.num_venues feed.num_venues
	json.num_users feed.num_users
	json.is_member? FeedUser.where("user_id = ? AND feed_id = ?", @user.id, feed.id).any?
end