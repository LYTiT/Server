json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.open feed.open
	json.created_at feed.created_at
	json.venue_added feed.feed_venues.where("venue_id =?", @venue_id).first.present?
	json.num_users	feed.num_users
	json.num_venues feed.num_venues
	json.num_moments feed.num_moments
	json.feed_color feed.feed_color
	json.users_can_add_places feed.open
	json.creator feed.user
	json.has_added feed.feed_users.where("user_id = ?", @viewer.id).first.present?
	json.list_description feed.description
	json.subscribed feed.feed_users.where("user_id = ?", @viewer.id).first.try(:is_subscribed)
	json.num_likes @num_likes
	json.preview_image_url feed.preview_image_url
	json.cover_image_url feed.cover_image_url
end