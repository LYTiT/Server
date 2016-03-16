json.array! @suggestions do |v|
  json.id v.id
  json.name v.name
  json.formatted_address v.address
  json.city v.city
  json.country v.country
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.rating
end