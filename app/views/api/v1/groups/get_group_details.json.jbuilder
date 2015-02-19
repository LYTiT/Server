json.id @group.id
json.name @group.name
json.is_member @group.is_user_member?(@user.id)
json.is_group_admin @group.is_user_admin?(@user.id)
json.is_public @group.is_public
json.description @group.description
json.num_group_members @group.users.count
json.num_group_venues @group.venues.count