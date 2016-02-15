json.cache! @comments, expires_in: 3.minutes, key: @view_cache_key  do |json|
  json.comments(@comments) do |comment|
    json.id comment.id
    json.instagram_id comment.instagram_id
    json.media_type comment.media_type
    json.media_url comment.image_url_2
    json.image_url_1 comment.image_url_1
    json.image_url_2 comment.image_url_2
    json.image_url_3 comment.image_url_3
    json.video_url_1 comment.video_url_1
    json.video_url_2 comment.video_url_2
    json.video_url_3 comment.video_url_3    
    json.created_at comment.time_wrapper
    json.content_origin comment.content_origin
    json.venue_id comment.venue_id
    json.thirdparty_username comment.thirdparty_username
  end  
end
json.venue_id @venue_id