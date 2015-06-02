json.everything_moments(@surrounding_bounties) do |entry|
  json.type entry.type

  json.id entry.id
  json.created_at entry.created_at
  json.venue_id entry.venue_id
  json.venue_name entry.venue.name
  json.city entry.venue.city
  json.state entry.venue.state
  json.country entry.venue.country
  json.latitude entry.venue.latitude
  json.longitude entry.venue.longitude
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
  json.latest_response_1 entry.bounty.try(:latest_response_1)
  json.latest_response_2 entry.bounty.try(:latest_response_2)
  json.latest_response_3 entry.bounty.try(:latest_response_3)
  json.latest_response_4 entry.bounty.try(:latest_response_4)
  json.latest_response_5 entry.bounty.try(:latest_response_5)
  json.latest_response_6 entry.bounty.try(:latest_response_6)
  json.latest_response_7 entry.bounty.try(:latest_response_7)
  json.latest_response_8 entry.bounty.try(:latest_response_8)
  json.latest_response_9 entry.bounty.try(:latest_response_9)
  json.latest_response_10 entry.bounty.try(:latest_response_10)
  json.did_respond @user.did_respond?(entry.bounty)

  json.compare_type entry.venue.type

  json.status entry.status

end
json.pagination do
  json.current_page @surrounding_bounties.current_page
  json.total_pages @surrounding_bounties.total_pages
end