json.array! @bounties do |bounty|
	json.id bounty.id
	json.created_at bounty.created_at 
	json.expiration bounty.expiration
	json.minutes_left bounty.minutes_left
	json.lumen_reward bounty.lumen_reward
	json.venue_name bounty.venue.name
	json.comment bounty.detail
  	json.media_type bounty.media_type
  	json.response_received bounty.response_received
  	json.validity bounty.validity
  	json.claims_count bounty.bounty_claims.count
end