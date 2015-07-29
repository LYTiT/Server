json.venues(@venues) do |v|
  json.id v.id
  json.name v.name
  json.city v.city
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
  json.last_post_time v.last_post_time
end

json.pagination do 
  json.current_page @venues.current_page
  json.total_pages @venues.total_pages
end