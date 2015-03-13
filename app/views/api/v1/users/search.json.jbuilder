json.array! @person do |u|
  json.id u.id
  json.name u.name
  json.email u.email
  json.lumen_value u.lumens
  json.is_following @user.following?(u)
  json.created_at u.created_at
  json.updated_at u.updated_at
  json.followers_count u.followers.count
  json.following_count (u.followed_users.count + u.followed_venues.count)
  json.media_url (u.last_three_comments[0]).try(:media_url)
  json.media_type (u.last_three_comments[0]).try(:media_type)
end