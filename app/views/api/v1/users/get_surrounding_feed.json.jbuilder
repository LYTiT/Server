json.array! @surrounding_feed do |entry|
	json.id entry.id 
	json.created_at entry.created_at
  json.updated_at entry.updated_at

	json.expiration entry.try(:expiration)
	json.lumen_reward entry.try(:lumen_reward)
  json.venue_id entry.try(:venue_id)
	json.venue_name entry.try(:venue).name
	json.comment entry.try(:comment)
	json.media_type entry.try(:media_type)
	json.response_received entry.try(:response_received)
	json.validity entry.try(:validity)
	json.claims_count entry.try(:bounty_claims).count
  json.minutes_left entry.try(:minutes_left)

	json.user_id entry.try(:user_id)
	json.bounty_id entry.try(:bounty_id)
	json.venue_comment_id entry.try(:venue_comment_id)

  json.media_url entry.try(:media_url)
  json.user_name entry.try(:user).name
  json.username_private entry.try(:username_private)
  json.total_views entry.try(:views)
end
json.pagination do
  json.current_page @surrounding_feed.current_page
  json.total_pages @surrounding_feed.total_pages
end