json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.created_at feed.created_at
end