json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.created_at feed.created_at
	json.venue_added feed.is_venue_present?(@venue_id)
	json.num_venues feed.num_venues
	json.num_users	feed.num_users
	json.new_content feed.new_content_for_user?(@user)
	json.feed_color feed.feed_color
	json.users_can_add_places feed.open
	json.creator feed.user
	json.has_added 1
	json.list_description feed.description
	json.subscribed feed.is_subscribed?(@user)
end