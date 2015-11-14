json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.creator feed.user
	json.num_venues feed.num_venues
	json.num_users feed.num_users
	json.has_added feed.feed_users.where("user_id = ?", @user.id).first.try(:is_subscribed)
	json.feed_color feed.feed_color
end