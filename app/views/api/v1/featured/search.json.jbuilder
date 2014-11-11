json.array! @person do |u|
  json.id u.id
  json.name u.name
  json.email u.email
  json.is_following @user.following?(u)
  json.created_at u.created_at
  json.updated_at u.updated_at
  json.followers_count u.followers.count
  json.following_count (u.followed_users.count + u.followed_venues.count)
end