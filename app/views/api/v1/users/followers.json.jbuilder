json.array! @followers do |follower|
	json.id follower.id
	json.name follower.name
	json.email follower.email
	json.created_at follower.created_at
  	json.updated_at follower.updated_at
  	json.followers_count follower.followers.count
  	json.following_count (follower.followed_users.count + follower.followed_venues.count)
end
