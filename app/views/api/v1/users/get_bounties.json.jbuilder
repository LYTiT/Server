json.array! @bounties do |bounty|
	json.id bounty.id
	json.user_id bounty.user_id
	json.venue_id bounty.venue_id
	json.created_at bounty.created_at 
	json.expiration bounty.expiration
	json.minutes_left bounty.minutes_left
	json.lumen_reward bounty.lumen_reward
	json.venue_name bounty.venue.name
	json.comment bounty.detail
  	json.media_type bounty.media_type
  	json.response_received bounty.response_received
  	json.validity bounty.validity
  	json.claims_count bounty.total_valid_claims
  	json.new_claims bounty.new_claims
  	json.is_subscribed 1
  	json.num_subscribed bounty.num_subscribed
  	json.num_responses bounty.num_responses-1
end