json.array! @recommendations do |v|
  json.id v.id
  json.name v.name
  json.media_url v.last_image.media_url
  json.media_type v.last_image.media_type
  json.formatted_address v.address
  json.city v.city
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
end