json.array! @users do |u|
  json.id u.id
  json.created_at u.created_at
  json.updated_at u.updated_at
  json.email u.email
  json.name u.name
end