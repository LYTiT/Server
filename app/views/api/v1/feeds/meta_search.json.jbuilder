json.array! @results do |feed|
	json.id feed.id
	json.name feed.name
	json.list_description feed.description
	json.created_at feed.created_at
	json.num_venues feed.num_venues
	json.num_users	feed.num_users
	json.feed_color feed.feed_color
end