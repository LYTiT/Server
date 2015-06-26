json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.created_at feed.created_at
	json.venue_added FeedVenue.where("feed_id = ? AND venue_id = ?", feed.id, @venue_id).any?
	json.num_venues feed.venues.count
end