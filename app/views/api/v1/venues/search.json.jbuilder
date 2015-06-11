json.meta_places(@venues) do |v|
  json.id v.id
  json.name v.name
  json.formatted_address v.formatted_address
  json.address v.address
  json.city v.city
  json.state v.state
  json.country v.country
  json.postal_code v.postal_code
  json.latitude v.latitude
  json.longitude v.longitude
  json.phone_number v.phone_number
  json.color_rating v.color_rating
  json.outstanding_bounties v.outstanding_bounties
  json.is_hot v.is_hot?
  json.bonus_lumens v.bonus_lumens
  json.compare_type v.type
end
