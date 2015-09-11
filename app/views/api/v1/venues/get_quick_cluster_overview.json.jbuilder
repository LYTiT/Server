json.post_id @post.id
json.comment @post.comment
json.media_type @post.media_type
json.media_url @post.media_url
json.post_created_at @post.time_wrapper
json.content_origin @post.content_origin
json.thirdparty_username @post.thirdparty_username

json.meta_1 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[0].meta
json.meta_2 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[1].meta
json.meta_3 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[2].meta
json.meta_4 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[3].meta
json.meta_5 @venue.meta_datas.order("relevance_score DESC LIMIT 5")[4].meta