json.everything_moments(@area_feed) do |entry|
  json.id entry.id
  json.created_at entry.created_at
  json.venue_id entry.venue_id
  json.venue_name entry.venue.name
  json.city entry.venue.city
  json.state entry.venue.state
  json.country entry.venue.country
  json.latitude entry.venue.latitude
  json.longitude entry.venue.longitude
 
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
  json.latest_response_1 entry.bounty.try(:latest_response_1)
  json.latest_response_2 entry.bounty.try(:latest_response_2)
  json.did_respond @user.did_respond?(entry.bounty)

  json.compare_type entry.venue.type

  json.status entry.status

end
json.pagination do
  json.current_page @area_feed.current_page
  json.total_pages @area_feed.total_pages
end