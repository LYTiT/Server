json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.latitude v.latitude
  json.longitude v.longitude
  json.color_rating v.color_rating
  json.outstanding_bounties v.outstanding_bounites
  json.has_menue v.has_menue?
end
