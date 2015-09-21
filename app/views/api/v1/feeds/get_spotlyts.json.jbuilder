json.array! @spotlyts do |feed|
	json.id feed.id
	json.has_added feed.has_added?(@user)
	json.name feed.name
	json.list_description feed.description
	json.created_at feed.created_at
	json.num_venues feed.num_venues
	json.num_users	feed.num_users
	json.feed_color feed.feed_color
	json.image_url feed.image_url
end