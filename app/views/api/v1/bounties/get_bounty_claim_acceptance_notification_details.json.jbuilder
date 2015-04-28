json.set! :bounty do
  json.set! :venue_name, @bounty.venue.name
  json.set! :created_at, @bounty.created_at
  json.set! :lumen_reward, @bounty.lumen_reward
end