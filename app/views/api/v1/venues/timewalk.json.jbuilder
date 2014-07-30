json.venues(@venues[:venues]) do |v|
  json.id v["id"]
  json.name v["name"]
  json.latitude v["latitude"]
  json.longitude v["longitude"]
  json.color_rating v["color_rating"]
  json.timewalk_color_ratings v["timewalk_color_ratings"]
end
json.checkins @venues[:checkins]
