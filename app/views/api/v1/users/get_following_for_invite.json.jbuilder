json.array! @prospects do |prospect|
	json.id prospect.id
	json.name prospect.name
	json.email prospect.email
end