json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.formatted_address v.address
  json.city v.city
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
  json.time_zone_offset v.time_zone_offset
  json.comments v.venue_comments.order("id DESC LIMIT 5")
end