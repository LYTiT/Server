json.array! @requests do |request|
  json.id request.id
  json.venue_id request.venue_id
  json.venue_name request.venue.name
  json.venue_address request.venue.address
  json.venue_city request.venue.city
  json.latitude request.latitude
  json.longitude request.longitude
  json.num_requesters request.num_requesters
end