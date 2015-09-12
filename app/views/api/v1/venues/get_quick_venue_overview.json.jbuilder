json.id @venue.id
json.name @venue.name
json.formatted_address @venue.address
json.city @venue.city
json.latitude @venue.latitude
json.longitude @venue.longitude
json.color_rating @venue.color_rating
json.time_zone_offset @venue.time_zone_offset

json.post_id @venue.venue_comments.order("id DESC LIMIT 1).first.id
json.comment @venue.venue_comments.order("id DESC LIMIT 1).first.comment
json.media_type @venue.venue_comments.order("id DESC LIMIT 1).first.media_type
json.media_url @venue.venue_comments.order("id DESC LIMIT 1).first.image_url_1
json.post_created_at @venue.venue_comments.order("id DESC LIMIT 1).first.time_wrapper
json.content_origin @venue.venue_comments.order("id DESC LIMIT 1).first.content_origin
json.thirdparty_username @venue.venue_comments.order("id DESC LIMIT 1).first.thirdparty_username

json.meta_1 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[0].meta
json.meta_2 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[1].meta
json.meta_3 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[2].meta
json.meta_4 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[3].meta
json.meta_5 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[4].meta