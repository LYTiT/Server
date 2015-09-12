json.id @venue.id
json.name @venue.name
json.formatted_address @venue.address
json.city @venue.city
json.latitude @venue.latitude
json.longitude @venue.longitude
json.color_rating @venue.color_rating
json.time_zone_offset @venue.time_zone_offset

json.post @venue.venue_comments.order("id DESC LIMIT 1")[0]

json.meta_1 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[0].try(:meta)
json.meta_2 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[1].try(:meta)
json.meta_3 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[2].try(:meta)
json.meta_4 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[3].try(:meta)
json.meta_5 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[4].try(:meta)