json.array! @venues do |v|
	json.id
	json.name
	json.address
	json.latitude
	json.longitude
	json.city
	json.country
	json.color_rating
	json.user_list_id

	json.image_url_1 comment.image_url_1
	json.image_url_2 comment.image_url_2
	json.image_url_3 comment.image_url_3

	json.event_id comment.event["id"]
	json.event_name comment.event["name"]
	json.event_description comment.event["description"]
	json.event_start_time comment.event["start_time"].to_i
	json.event_end_time comment.event["end_time"].to_i
	json.cover_image_url comment.event["cover_image_url"]
end