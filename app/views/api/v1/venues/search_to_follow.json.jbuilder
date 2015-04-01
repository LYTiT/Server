json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.formatted_address v.address
  json.media_url v.last_media_comment_url
  json.media_type v.last_media_comment_type
  json.city v.city
  json.latitude v.latitude
  json.longitude v.longitude
  json.is_following @user.vfollowing?(v)
  json.color_rating v.color_rating
end
