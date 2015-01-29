json.array! @bounties do |bounty|
	json.id bounty.id
	json.created_at bounty.created_at 
	json.expiration bounty.expiration.to_time
	json.lumen_reward bounty.lumen_reward
	json.venue_name bounty.venue.name
	json.comment bounty.comment
  	json.media_type bounty.media_type
  	json.response_received bounty.response_received
end