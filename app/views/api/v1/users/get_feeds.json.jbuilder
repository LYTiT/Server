json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.created_at feed.created_at
	json.venue_added feed.venue_added?(@venue_id)
end