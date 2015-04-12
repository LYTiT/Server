json.array! @bounty_claims do |bounty_claim|
	json.venue_name bounty_claim.bounty.venue.name
	json.venue_comment_id bounty_claim.id
	json.media_type bounty_claim.bounty.media_type
	json.lumen_reward bounty_claim.bounty.lumen_reward
	json.created_at bounty_claim.created_at
	json.minutes_left bounty_claim.bounty.try(:minutes_left)
end