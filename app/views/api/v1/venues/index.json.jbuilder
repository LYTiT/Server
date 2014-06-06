json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.rating v.rating
  json.phone_number v.phone_number
  json.address v.address
  json.city v.city
  json.state v.state
  json.created_at v.created_at
  json.updated_at v.updated_at
  json.latitude v.latitude
  json.longitude v.longitude
  json.google_place_rating v.google_place_rating
  json.google_place_key v.google_place_key
  json.country v.country
  json.postal_code v.postal_code
  json.formatted_address v.formatted_address
  json.google_place_reference v.google_place_reference
  json.distance v.distance
end
