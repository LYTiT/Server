json.cache! @comments, expires_in: 3.minutes, key: @view_cache_key  do |json|
  json.comments(@comments) do |comment|
    json.id nil
    json.instagram_id comment["id"]
    json.media_type comment["type"]
    json.media_url comment["images"]["low_resolution"].try(:[], "url")
    json.image_url_1 comment["images"]["thumbnail"].try(:[], "url")
    json.image_url_2 comment["images"]["low_resolution"].try(:[], "url")
    json.image_url_3 comment["images"]["standard_resolution"].try(:[], "url")
    json.video_url_1 comment["videos"].try(:[], "low_bandwidth").try(:[], "url")
    json.video_url_2 comment["videos"].try(:[], "low_resolution").try(:[], "url")
    json.video_url_3 comment["videos"].try(:[], "standard_resolution").try(:[], "url")    
    json.created_at DateTime.strptime(comment["created_time"],'%s')
    json.content_origin 'instagram'
    json.venue_id @venue_id
    json.thirdparty_username comment["user"]["username"]
  end
end
json.venue_id @venue_id