json.array! @venues do |venue|
  json.id venue.id
  json.name venue.name
  json.formatted_address venue.address
  json.city venue.get_city_implicitly
  json.latitude venue.latitude
  json.longitude venue.longitude
  json.color_rating venue.rating
  json.trend_position venue.trend_position
end