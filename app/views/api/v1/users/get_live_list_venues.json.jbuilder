json.array! @venues do |venue|
  json.id venue.id  
  json.name venue.name
  json.formatted_address venue.formatted_address
  json.address venue.address
  json.city venue.city
  json.state venue.state
  json.country venue.country
  json.postal_code venue.postal_code
  json.latitude venue.latitude
  json.longitude venue.longitude
  json.phone_number venue.phone_number
  json.color_rating venue.rating
  json.time_zone_offset venue.time_zone_offset
end