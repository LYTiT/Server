json.comments(@news) do |entry|
	json.id entry.id
	json.comment entry.comment
	json.media_type entry.media_type
	json.media_url entry.media_url
	json.user_id entry.user_id
	json.user_name entry.user.try(:name)
	json.username_private entry.username_private
	json.venue_id entry.venue_id
	json.venue_name entry.venue.try(:name)
	json.viewed entry.is_viewed?(@user)
	json.total_views entry.views
	json.created_at entry.created_at
	json.updated_at entry.updated_at
	json.group_1_name entry.hashtags[0].try(:name)
	json.group_1_id entry.hashtags[0].try(:id)
	json.group_2_name entry.hashtags[1].try(:name)
	json.group_2_id entry.hashtags[1].try(:id)
	json.group_3_name entry.hashtags[2].try(:name)
	json.group_3_id entry.hashtags[2].try(:id)
	json.group_4_name entry.hashtags[3].try(:name)
	json.group_4_id entry.hashtags[3].try(:id)
	json.group_5_name entry.hashtags[4].try(:name)
	json.group_5_id entry.hashtags[4].try(:id)
	json.from_user 0
end
json.pagination do
  json.current_page @news.current_page
  json.total_pages @news.total_pages
end