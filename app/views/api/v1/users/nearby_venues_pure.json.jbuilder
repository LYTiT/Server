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
end