json.array! @person do |u|
  json.id u.id
  json.name u.name
  json.email u.email
  json.lumen_value u.lumens
  json.is_following @user.following?(u)
  json.created_at u.created_at
  json.updated_at u.updated_at
end