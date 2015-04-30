json.set! :bounty do
  json.set! :venue_name, @bounty.venue.name
  json.set! :created_at, @bounty.created_at
  json.set! :reason, @bounty_claim.rejection_reason
end