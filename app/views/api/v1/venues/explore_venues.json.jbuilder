json.array! @venues do |v|
	json.id v.id
	json.name v.name
	json.formatted_address v.address
	json.city v.city
	json.latitude v.latitude
	json.longitude v.longitude
	json.color_rating v.color_rating
	json.time_zone_offset v.time_zone_offset

	json.post_id v.venue_comments.order("id DESC LIMIT 1")[0].try(:id)
	json.comment v.venue_comments.order("id DESC LIMIT 1")[0].try(:comment)
	json.media_type v.venue_comments.order("id DESC LIMIT 1")[0].try(:media_type)
	json.media_url v.venue_comments.order("id DESC LIMIT 1")[0].try(:image_url_1)
	json.post_created_at v.venue_comments.order("id DESC LIMIT 1")[0].try(:time_wrapper)
	json.content_origin v.venue_comments.order("id DESC LIMIT 1")[0].try(:content_origin)
	json.thirdparty_username v.venue_comments.order("id DESC LIMIT 1")[0].try(:thirdparty_username)

	json.meta_1 v.meta_datas.order("relevance_score DESC LIMIT 5")[0].try(:meta)
	json.meta_2 v.meta_datas.order("relevance_score DESC LIMIT 5")[1].try(:meta)
	json.meta_3 v.meta_datas.order("relevance_score DESC LIMIT 5")[2].try(:meta)
	json.meta_4 v.meta_datas.order("relevance_score DESC LIMIT 5")[3].try(:meta)
	json.meta_5 v.meta_datas.order("relevance_score DESC LIMIT 5")[4].try(:meta)

end