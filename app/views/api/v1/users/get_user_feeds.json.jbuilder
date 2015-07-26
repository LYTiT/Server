json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.created_at feed.created_at
	json.venue_added feed.is_venue_present?(@venue_id)
	json.num_venues feed.num_venues
	json.new_content feed.new_media_present
	json.feed_color feed.feed_color
	json.open feed.open
	json.creator feed.user
	json.has_added 1
end