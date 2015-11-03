json.array! @lists do |list|
	json.id list.id
	json.name list.name
	json.created_at list.created_at
	json.venue_added list.is_venue_present?(@venue_id)	
	json.num_users	list.num_users
	json.num_venues list.num_venues
	json.num_moments list.num_moments
	json.list_color list.feed_color
	json.users_can_add_places list.open
	json.creator list.user
	json.has_added 1
	json.list_description list.description
	json.total_pages @lists.total_pages
end