json.meta_places(@venues) do |v|
  json.id v.id
  json.name v.name
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
  json.comment_1 v.meta_search_sanity_check(v.venue_comments[0], @query)
  json.comment_1_username v.venue_comments[0].user.try(:name)
  json.comment_1_thirdparty_username v.venue_comments[0].user.try(:thirdparty_username)
  json.comment_1_user_lumens v.venue_comments[0].user.try(:lumens)
  json.comment_2 v.meta_search_sanity_check(v.venue_comments[1], @query)
  json.comment_2_username v.venue_comments[0].user.try(:name)
  json.comment_2_thirdparty_username v.venue_comments[0].user.try(:thirdparty_username)
  json.comment_2_user_lumens v.venue_comments[0].user.try(:lumens)
  json.comment_3 v.meta_search_sanity_check(v.venue_comments[2], @query)
  json.comment_3_username v.venue_comments[0].user.try(:name)
  json.comment_3_thirdparty_username v.venue_comments[0].user.try(:thirdparty_username)
  json.comment_3_user_lumens v.venue_comments[0].user.try(:lumens)
end
json.pagination do 
  json.current_page @venues.current_page
  json.total_pages @venues.total_pages
end