json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.city v.city
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.rating
end
