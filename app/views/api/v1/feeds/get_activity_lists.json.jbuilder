json.array! @lists do |list|
	json.id list.id
	json.name list.name
	json.created_at list.created_at
	json.num_users	list.num_users
	json.num_venues list.num_venues
	json.num_moments list.num_moments
	json.feed_color list.feed_color
	json.users_can_add_places list.open
	json.creator list.user
	json.has_added list.feed_users.where("user_id = ?", @user.id).first.present?
	json.list_description list.description
end