json.array! @suggestions do |v|
  json.id v.id
  json.name v.name
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
end