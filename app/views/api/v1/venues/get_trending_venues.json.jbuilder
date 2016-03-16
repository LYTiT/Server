json.cache_collection! @venues, expires_in: 5.minutes do |v|
  json.id v.id
  json.name v.name
  json.formatted_address v.address
  json.city v.get_city_implicitly
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.rating
  json.trend_position v.trend_position
end