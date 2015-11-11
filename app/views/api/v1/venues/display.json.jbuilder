json.cache! @venues, expires_in: 5.minutes, key: @view_cache_key  do |json|
	json.array! @venues do |v|
	  json.id v.id
	  json.name v.name
	  json.city v.city
	  json.country v.country
	  json.latitude v.latitude
	  json.longitude v.longitude
	  json.color_rating v.color_rating
	  json.last_post_time v.last_post_time
	  json.instagram_location_id v.instagram_location_id
	  json.event_id v.event_id
	end
end
