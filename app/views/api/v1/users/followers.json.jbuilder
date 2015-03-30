json.array! @followers do |follower|
	json.id follower.id
	json.name follower.name
	json.email follower.email
	json.created_at follower.created_at
  	json.updated_at follower.updated_at
  	json.followers_count follower.followers.count
  	json.following_count (follower.followed_users.count + follower.followed_venues.count)
  	json.is_following @user.following?(follower)
  	json.media_url (follower.last_media_comment).try(:media_url)
	json.media_type (follower.last_media_comment).try(:media_type)
end
