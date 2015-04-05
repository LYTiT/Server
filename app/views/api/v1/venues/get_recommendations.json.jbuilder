json.array! @recommendations do |v|
  json.id v.id
  json.name v.name
  json.last_media_comment_url v.last_media_comment_url
  json.last_media_comment_type v.last_media_comment_type
  json.formatted_address v.address
  json.city v.city
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
end