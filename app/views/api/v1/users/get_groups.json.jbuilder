json.array! @groups do |group|
  json.id group.id
  json.name group.name
  json.description group.description
  json.num_group_members group.users_count
  json.num_group_venues group.venues_count
  json.can_link_venues group.can_link_venues
  json.is_public group.is_public
  json.created_at group.created_at
  json.updated_at group.updated_at
  json.is_group_admin group.is_user_admin?(@user.id)
  json.group_password group.return_password_if_admin(@user.id)
  json.send_notification GroupsUser.send_notification?(group.id, @user.id)
  json.cover_media_url group.cover_media_url
end
