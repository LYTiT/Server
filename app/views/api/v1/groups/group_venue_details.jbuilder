json.set! :venue do
  json.id @venue.id
  json.name @venue.name
  json.rating @venue.rating
  json.phone_number @venue.phone_number
  json.address @venue.address
  json.city @venue.city
  json.state @venue.state
  json.created_at @venue.created_at
  json.updated_at @venue.updated_at
  json.latitude @venue.latitude
  json.longitude @venue.longitude
  json.google_place_rating @venue.google_place_rating
  json.google_place_key @venue.google_place_key
  json.country @venue.country
  json.postal_code @venue.postal_code
  json.formatted_address @venue.formatted_address
  json.google_place_reference @venue.google_place_reference
end

json.set! :group do
  json.id @group.id
  json.name @group.name
  json.description @group.description
  json.is_public @group.is_public
  json.created_at @group.created_at
  json.updated_at @group.updated_at
  json.is_group_admin @group.is_user_admin?(@user.id)
  json.send_notification GroupsUser.send_notification(@group.id, @user.id)
end