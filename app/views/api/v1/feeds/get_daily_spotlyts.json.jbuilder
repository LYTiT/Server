json.array! @spotlyts do |spotlyt|
	json.id spotlyt.feed.id
	json.has_added spotlyt.feed.has_added?(@user)
	json.name spotlyt.feed.name
	json.creator spotlyt.feed.user.try(:partial)
	json.list_description spotlyt.feed.description
	json.created_at spotlyt.feed.created_at
	json.num_venues spotlyt.feed.num_venues
	json.num_users	spotlyt.feed.num_users
	json.preview_image_url spotlyt.feed.preview_image_url
	json.cover_image_url spotlyt.feed.cover_image_url
	json.feed_color spotlyt.feed.feed_color
end