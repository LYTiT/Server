json.cache! @venues, expires_in: 5.minutes, key: @view_cache_key do |json|
  json.venues(@venues) do |v|
    json.id v.id
    json.name v.name
    json.address v.address
    json.city v.city
    json.country v.country
    json.latitude v.latitude
    json.longitude v.longitude
    json.color_rating v.color_rating
    json.trending_score v.popularity_rank
    json.last_post_time v.last_post_time
    json.instagram_location_id v.instagram_location_id
    json.event_id v.event_id
    json.preview_image v.latest_post_details["image_url_1"]
    json.full_image v.latest_post_details["image_url_2"]
    json.full_video v.latest_post_details["video_url_2"]
    json.tag_1 v.tag_1
    json.tag_2 v.tag_2
    json.tag_3 v.tag_3
    json.tag_4 v.tag_4
    json.tag_5 v.tag_5
  end
end
