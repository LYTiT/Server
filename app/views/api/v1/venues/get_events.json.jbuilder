json.array! @events do |event|
	json.id event.id
	json.name event.name
	json.description event.description
	json.start_time event.start_time
	json.end_time event.end_time
	json.created_at event.created_at
	json.source_url event.source_url
	json.cover_image_url event.cover_image_url
end