json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
  json.comment_1 v.venue_comments.order("id desc limit 3")[0]
  json.comment_2 v.venue_comments.order("id desc limit 3")[1]
  json.comment_3 v.venue_comments.order("id desc limit 3")[2]
end