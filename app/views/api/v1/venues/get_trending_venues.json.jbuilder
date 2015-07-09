json.cache_collection! @venues, expires_in: 5.minutes do |v|
  json.id v.id
  json.name v.name
  json.formatted_address v.address
  json.city v.get_city_implicitly
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
  json.comment_1 v.venue_comments.order("id desc")[0]
  json.comment_1_username v.venue_comments[0].try(:username_for_trending_venue_view)
  json.comment_2 v.venue_comments.order("id desc")[1]
  json.comment_2_username v.venue_comments[1].try(:username_for_trending_venue_view)
  json.comment_3 v.venue_comments.order("id desc")[2]
  json.comment_3_username  v.venue_comments[2].try(:username_for_trending_venue_view)
  json.comment_4 v.venue_comments.order("id desc")[3]
  json.comment_4_username v.venue_comments[3].try(:username_for_trending_venue_view)
  json.comment_5 v.venue_comments.order("id desc")[4]
  json.comment_5_username v.venue_comments[4].try(:username_for_trending_venue_view)
  json.trend_position v.trend_position
end