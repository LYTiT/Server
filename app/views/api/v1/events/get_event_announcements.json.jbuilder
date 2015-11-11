json.array! @event_announcements do |event_announcement|
	json.comment event_annoucement.comment
	json.created_at event_annoucement.created_at
end