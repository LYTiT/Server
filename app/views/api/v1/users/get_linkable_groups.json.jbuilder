json.array! @groups do |group|
  json.id group.id
  json.name group.name
  json.description group.description
  json.num_group_members group.users_count
  json.num_group_venues group.venues_count
end