json.array! @user.groups do |group|
  json.id group.id
  json.name group.name
  json.description group.description
  json.is_public group.is_public
  json.created_at group.created_at
  json.updated_at group.updated_at
  json.is_group_admin group.is_user_admin?(@user.id)
  json.group_password group.return_password_if_admin(@user.id)
  json.send_notification GroupsUser.send_notification(group.id, @user.id)
end
