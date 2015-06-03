json.array! @bounties do |bounty|
  json.id bounty.venue.id
  json.name bounty.venue.name
end
