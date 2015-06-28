json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.created_at feed.created_at
	json.venue_added feed.is_venue_present?(@venue_id)
	json.num_venues feed.num_venues
	json.new_content feed.new_content_present?
end