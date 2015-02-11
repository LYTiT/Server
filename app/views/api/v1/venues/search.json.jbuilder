json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.latitude v.latitude
  json.longitude v.longitude
  json.postal_code v.postal_code
  json.color_rating v.color_rating
  json.is_linked_to_group v.is_linked_to_group?(@group_id)
end
