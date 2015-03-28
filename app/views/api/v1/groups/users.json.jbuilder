json.array! @group.users do |user|
  json.id user.id
  json.created_at user.created_at
  json.updated_at user.updated_at
  json.email user.email
  json.name user.name
  json.notify_location_added_to_groups user.notify_location_added_to_groups
  json.notify_events_added_to_groups user.notify_events_added_to_groups
  json.notify_venue_added_to_groups user.notify_venue_added_to_groups
  json.is_group_admin @group.is_user_admin?(user.id)
  json.send_notification GroupsUser.send_notification?(@group.id, user.id)
  json.media_url (user.last_three_comments[0]).try(:media_url)
  json.media_type (user.last_three_comments[0]).try(:media_type)
end
