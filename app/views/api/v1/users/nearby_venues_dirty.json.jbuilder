json.array! @venues do |venue|
  json.id nil
  json.instagram_location_id venue["location"]["id"]
  json.name venue["location"]["name"]
  json.address nil
  json.city nil
  json.formatted_address nil
  json.state nil
  json.country nil
  json.postal_code nil 
  json.latitude venue["location"]["latitude"]
  json.longitude venue["location"]["longitude"]
  json.color_rating nil
end