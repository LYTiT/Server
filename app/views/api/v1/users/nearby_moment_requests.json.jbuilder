json.array! @requests do |request|
  json.id request.id
  json.venue_id request.venue_id
  json.venue_name request.venue.name
  json.venue_latitude request.latitude
  json.venue_longitude request.longitude
  json.num_requesters request.num_requesters
end