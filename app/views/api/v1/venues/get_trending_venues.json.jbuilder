json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.formatted_address v.address
  json.city v.city
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
  json.comment_1 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[0]
  json.comment_1_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[0].username_for_trending_venue_view
  json.comment_2 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[1]
  json.comment_2_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[1].username_for_trending_venue_view
  json.comment_3 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[2]
  json.comment_3_username  v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[2].username_for_trending_venue_view
  json.comment_4 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[3]
  json.comment_4_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[3].username_for_trending_venue_view
  json.comment_5 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[4]
  json.comment_5_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[4].username_for_trending_venue_view
  json.comment_6 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[5]
  json.comment_6_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[5].username_for_trending_venue_view
  json.comment_7 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[6]
  json.comment_7_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[6].username_for_trending_venue_view
  json.comment_8 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[7]
  json.comment_8_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[7].username_for_trending_venue_view
  json.comment_9 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[8]
  json.comment_9_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[8].username_for_trending_venue_view
  json.comment_10 v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[9]
  json.comment_10_username v.venue_comments.where("(NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")[9].username_for_trending_venue_view
  json.ranking_change v.ranking_change(@venue_hash[v])
end