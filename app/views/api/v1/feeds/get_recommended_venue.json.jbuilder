if @venue != nil
	json.id @venue.id
	json.name @venue.name
	json.address @venue.address
	json.city @venue.city
	json.country @venue.country
	json.latitude @venue.latitude
	json.longitude @venue.longitude
	json.color_rating @venue.color_rating
	json.trending_score @venue.popularity_rank
	json.last_post_time @venue.last_post_time
	json.instagram_location_id @venue.instagram_location_id
	json.event_id @venue.event_details["id"]
	if @venue.venue_comment_details["entry_type"] == "lytit_post"
	    json.preview_image @venue.venue_comment_details["lytit_post"]["image_url_1"]
	    json.full_image @venue.venue_comment_details["lytit_post"]["image_url_2"]
	    json.full_video @venue.venue_comment_details["lytit_post"]["video_url_2"]
	end
	if @venue.venue_comment_details["entry_type"] == "instagram"
	    json.preview_image @venue.venue_comment_details["instagram"]["image_url_1"]
	    json.full_image @venue.venue_comment_details["instagram"]["image_url_2"]
	    json.full_video @venue.venue_comment_details["instagram"]["video_url_2"]        
	end
	json.tag_1 @venue.trending_tags["tag_1"]
	json.tag_2 @venue.trending_tags["tag_2"]
	json.tag_3 @venue.trending_tags["tag_3"]
	json.tag_4 @venue.trending_tags["tag_4"]
	json.tag_5 @venue.trending_tags["tag_5"]
	json.foursquare_id @venue.foursquare_id
end