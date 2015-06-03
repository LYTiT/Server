json.array! @bounties do |bounty| 
  json.created_at bounty.created_at
  json.venue_id bounty.venue_id
  json.venue_name bounty.venue.name
  json.city bounty.venue.city
  json.state bounty.venue.state
  json.country bounty.venue.country
  json.latitude bounty.venue.latitude
  json.longitude bounty.venue.longitude

  json.bounty_id bounty.id
  json.request_media_type bounty.try(:media_type)
  json.lumen_reward bounty.try(:lumen_reward)
  json.minutes_left bounty.try(:minutes_left)
  json.details bounty.try(:detail)
  json.validity bounty.try(:validity)
  json.is_subscribed @user.is_subscribed_to_bounty?(entry.bounty)
  json.num_subscribed bounty.try(:num_subscribed)
  json.user_id bounty.try(:user_id)
  json.response_received bounty.try(:response_received)
  json.num_responses bounty.try(:num_responses)
  json.latest_response_1 bounty.try(:latest_response_1)
  json.latest_response_2 bounty.try(:latest_response_2)
  json.latest_response_3 bounty.try(:latest_response_3)
  json.latest_response_4 bounty.try(:latest_response_4)
  json.latest_response_5 bounty.try(:latest_response_5)
  json.latest_response_6 bounty.try(:latest_response_6)
  json.latest_response_7 bounty.try(:latest_response_7)
  json.latest_response_8 bounty.try(:latest_response_8)
  json.latest_response_9 bounty.try(:latest_response_9)
  json.latest_response_10 bounty.try(:latest_response_10)
  json.did_respond @user.did_respond?(entry.bounty)

  json.compare_type bounty.venue.type

  json.status bounty.status

end
json.pagination do
  json.current_page @bounties.current_page
  json.total_pages @bounties.total_pages
end