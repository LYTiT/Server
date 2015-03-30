json.array! @events do |event|
	json.id event.id
	json.name event.name
	json.description event.description
	json.start_date event.start_date
	json.end_date event.end_date
	json.single_venue_id event.venue_id
	json.single_venue_name event.venue.name
	json.single_venue_address event.venue.address
	json.latitude event.latitude
	json.longitude event.longitude
	json.expired event.expiration_check
end