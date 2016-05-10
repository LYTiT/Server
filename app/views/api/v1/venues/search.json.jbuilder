json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.formatted_address v.formatted_address
  json.address v.address
  json.city v.city
  json.state v.state
  json.country v.country
  json.postal_code v.postal_code
  json.latitude v.latitude
  json.longitude v.longitude
  json.phone_number v.phone_number
  json.color_rating v.color_rating
  json.time_zone_offset v.time_zone_offset
  json.is_meta_search @is_meta
  json.foursquare_id v.foursquare_id
  json.instagram_location_id v.instagram_location.id
end
