json.cache! @venues, expires_in: 1.hour, key: @view_cache_key  do |json|
  json.array! @venues do |venue|
    json.id venue.id
    json.instagram_location_id venue.instagram_location_id
    json.name venue.name
    json.address venue.address
    json.city venue.city
    json.formatted_address venue.formatted_address
    json.state venue.state
    json.country venue.country
    json.postal_code venue.postal_code
    json.latitude venue.latitude
    json.longitude venue.longitude
    json.color_rating venue.color_rating
    json.time_zone_offset venue.time_zone_offset
    json.tag_1 venue.meta_datas.order("relevance_score DESC LIMIT 1")
    json.tag_2 venue.meta_datas.order("relevance_score DESC LIMIT 1 OFFSET 1")
    json.tag_3 venue.meta_datas.order("relevance_score DESC LIMIT 1 OFFSET 2")
    json.tag_4 venue.meta_datas.order("relevance_score DESC LIMIT 1 OFFSET 3")
    json.tag_5 venue.meta_datas.order("relevance_score DESC LIMIT 1 OFFSET 4")
  end
end