json.array! @events do |event|
	json.id event.id
	json.name event.name
	json.description event.description
	json.start_date event.start_date
	json.end_date event.end_date
	json.venue_id event.venue_id
	json.venue_name event.venue.name
	json.venue_address event.venue.address
	json.latitude event.latitude
	json.longitude event.longitude
	json.expired event.expiration_check
end