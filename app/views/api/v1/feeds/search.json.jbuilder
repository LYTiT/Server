json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.open feed.open
	json.creator feed.user
	json.num_venues feed.num_venues

end