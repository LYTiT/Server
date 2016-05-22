json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.open feed.open
	json.feed_color feed.feed_color
	json.preview_image_url feed.preview_image_url
	json.creator feed.user.try(:partial)
end