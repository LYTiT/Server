json.array! @bounties do |bounty|
  json.id bounty.venue.name
  json.name bounty.venue.id
end
