json.everything_moments(@surrounding_feed) do |entry|
  json.type entry.type

  json.id entry.id
  json.created_at entry.created_at
  json.venue_id entry.venue_id
  json.venue_name entry.venue.name
  json.city entry.venue.city
  json.username_private entry.username_private
  json.media_type entry.media_type
  json.media_url entry.media_url
  json.comment entry.comment
  json.views entry.views

  json.bounty_id entry.bounty_id
  json.request_media_type entry.bounty.try(:media_type)
  json.lumen_reward entry.bounty.try(:lumen_reward)
  json.minutes_left entry.bounty.try(:minutes_left)
  json.details entry.bounty.try(:detail)
  json.validity entry.bounty.try(:validity)
  json.is_subscribed @user.is_subscribed_to_bounty?(entry.bounty)
  json.num_subscribed entry.bounty.try(:num_subscribed)
  json.user_id entry.bounty.try(:user_id)
  json.response_received entry.bounty.try(:response_received)
  json.num_responses entry.bounty.try(:num_responses)
  json.can_respond entry.can_user_respond?(location_details)

  json.status entry.status

end
json.pagination do
  json.current_page @surrounding_feed.current_page
  json.total_pages @surrounding_feed.total_pages
end