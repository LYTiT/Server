json.is_following @user.following?(@other_user)
json.followers_count @other_user.followers.count
json.following_count (@other_user.followed_users.count + @user.followed_venues.count)