json.array! @venues do |v|
	json.id v.id
	json.name v.name
	json.address v.address
	json.latitude v.latitude
	json.longitude v.longitude
	json.city v.city
	json.country v.country
	json.color_rating v.color_rating
	
	json.rec_reason v.recommendation_reason_for(@user)

	if v.venue_comment_details["entry_type"] == "lytit_post"
		json.image_url_1 v.venue_comment_details["lytit_post"]["image_url_1"]
		json.image_url_2 v.venue_comment_details["lytit_post"]["image_url_2"]
		json.image_url_3 v.venue_comment_details["lytit_post"]["image_url_3"]
	else
		json.image_url_1 v.venue_comment_details["instagram"]["image_url_1"]
		json.image_url_2 v.venue_comment_details["instagram"]["image_url_2"]
		json.image_url_3 v.venue_comment_details["instagram"]["image_url_3"]
	end

	json.event_id v.event_details["id"]
	json.event_name v.event_details["name"]
	json.event_description v.event_details["description"]
	json.event_start_time v.event_details["start_time"]
	json.event_end_time v.event_details["end_time"]
	json.cover_image_url v.event_details["cover_image_url"]
end