json.array! @venues do |v|
	json.id v.id
	json.name v.name
	json.formatted_address v.address
	json.city v.city
	json.latitude v.latitude
	json.longitude v.longitude
	json.color_rating v.color_rating
	json.time_zone_offset v.time_zone_offset
	json.instagram_location_id

	json.post v.venue_comments.order("id DESC LIMIT 1")[0]

	json.meta_1 v.meta_datas.order("relevance_score DESC LIMIT 5")[0].try(:meta)
	json.meta_2 v.meta_datas.order("relevance_score DESC LIMIT 5")[1].try(:meta)
	json.meta_3 v.meta_datas.order("relevance_score DESC LIMIT 5")[2].try(:meta)
	json.meta_4 v.meta_datas.order("relevance_score DESC LIMIT 5")[3].try(:meta)
	json.meta_5 v.meta_datas.order("relevance_score DESC LIMIT 5")[4].try(:meta)

end