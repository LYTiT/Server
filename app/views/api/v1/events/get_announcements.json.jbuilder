json.array! @event_announcements do |event_announcement|
	json.comment event_announcement.comment
	json.created_at event_announcement.created_at
end