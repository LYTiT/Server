json.meta_places(@venues) do |v|
  json.id v.id
  json.name v.name
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
  json.comment_1 v.venue_comments[0]
  json.comment_2 v.venue_comments[1]
  json.comment_3 v.venue_comments[2]
end
json.pagination do 
  json.current_page @venues.current_page
  json.total_pages @venues.total_pages
end