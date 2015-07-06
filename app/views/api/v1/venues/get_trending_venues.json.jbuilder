json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.formatted_address v.address
  json.city v.get_city_implicitly
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
  json.comment_1 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[0]
  json.comment_1_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[0].try(:username_for_trending_venue_view)
  json.comment_2 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[1]
  json.comment_2_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[1].try(:username_for_trending_venue_view)
  json.comment_3 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[2]
  json.comment_3_username  v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[2].try(:username_for_trending_venue_view)
  json.comment_4 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[3]
  json.comment_4_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[3].try(:username_for_trending_venue_view)
  json.comment_5 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[4]
  json.comment_5_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[4].try(:username_for_trending_venue_view)
  json.ranking_change v.ranking_change(@venue_hash[v])
end