json.array! @users do |user|
  json.id user.id
  json.created_at user.created_at
  json.updated_at user.updated_at
  json.email user.email
  json.name user.name
  json.is_group_admin @group.is_user_admin?(user.id)
  json.send_notification GroupsUser.send_notification?(@group.id, user.id)
end
