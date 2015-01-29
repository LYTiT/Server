json.array! @bounties do |bounty|
	json.id bounty.id
	json.created_at bounty.created_at 
	json.expiration bounty.expiration
	json.lumen_reward bounty.lumen_reward
	json.venue_name bounty.venue.name
  	json.media_type bounty.media_type
  	json.response_received bounty.response_received
  	json.created_at bounty.created_at
end