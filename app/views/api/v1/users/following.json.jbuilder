json.array! @followed_users do |followed_user|
	json.id followed_user.id
	json.name followed_user.name
	json.email followed_user.email
	json.created_at followed_user.created_at
  	json.updated_at followed_user.updated_at
  	json.is_following 1
  	json.followers_count followed_user.followers.count
  	json.following_count (followed_user.followed_users.count + followed_user.followed_venues.count)
  	json.media_url (followed_user.last_three_comments[0]).try(:media_url)
	json.media_type (followed_user.last_three_comments[0]).try(:media_type)
end
