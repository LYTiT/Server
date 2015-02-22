json.everything_moments(@surrounding_feed) do |entry|
	json.id entry.id 
	json.created_at entry.created_at
  json.updated_at entry.updated_at

	json.lumen_reward entry.try(:lumen_reward)
  json.venue_id entry.try(:venue_id)
	json.venue_name entry.try(:venue).try(:name)
  json.details entry.try(:detail)
	json.media_type entry.try(:media_type)
	json.response_received entry.try(:response_received)
	json.validity entry.try(:validity)
  json.minutes_left entry.try(:minutes_left)

	json.user_id entry.try(:user_id)
	json.bounty_id entry.try(:bounty_id)
  json.request_details entry.try(:bounty).try(:detail)
  json.request_lumen_reward entry.try(:bounty).try(:lumen_reward)
  json.response_comment entry.try(:venue_comment).try(:comment)
  json.response_venue_name entry.try(:bounty).try(:venue).try(:name)
  json.response_media_url entry.try(:venue_comment).try(:media_url)
  json.response_media_type entry.try(:bounty).try(:media_type)
	json.venue_comment_id entry.try(:venue_comment_id)

  json.media_url entry.try(:media_url)
  json.user_name entry.try(:user).try(:name)
  json.username_private entry.try(:username_private)
  json.comment entry.try(:comment)
end
json.pagination do
  json.current_page @surrounding_feed.current_page
  json.total_pages @surrounding_feed.total_pages
end