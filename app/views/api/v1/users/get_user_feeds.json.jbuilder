json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.created_at feed.created_at
	json.venue_added feed.venues.where("venues.id = ?", @venue.try(:id)).any?
	json.num_users	feed.num_users
	json.num_venues feed.num_venues
	json.num_moments feed.num_moments
	json.feed_color feed.feed_color
	json.users_can_add_places feed.open
	json.creator feed.user
	json.has_added feed.users.where("users.id = ?", @user.id).any?
	json.list_description feed.description
	json.subscribed feed.is_subscribed?(@user)
	json.num_likes @num_likes
end