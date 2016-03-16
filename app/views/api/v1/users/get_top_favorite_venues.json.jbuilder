json.array! @top_favorite_venues do |favorite_venue|
  json.favorite_venue_id favorite_venue.id
  json.id favorite_venue.venue_id
  json.name favorite_venue.venue_name
  json.latest_venue_check_time favorite_venue.latest_venue_check_time
  json.num_new_moments favorite_venue.num_new_moments
  json.latitude favorite_venue.venue_details["latitude"]
  json.longitude favorite_venue.venue_details["longitude"]
  json.color_rating favorite_venue.venue.rating
  json.address favorite_venue.venue.address
  json.city favorite_venue.venue.city
  json.state favorite_venue.venue.state
  json.country favorite_venue.venue.country
end