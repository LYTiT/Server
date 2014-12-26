json.is_user_memeber @group.is_user_member?(@user.id)
json.is_user_admin @group.is_user_admin?(@user.id)
json.is_public @group.is_public
json.description @group.description
json.members_count @group.users.count
json.venues_count @group.venues.count