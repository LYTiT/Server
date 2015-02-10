json.id @other_user.id
json.name @other_user.name
json.is_following @user.following?(@other_user)
json.followers_count @other_user.followers.count
json.following_count (@other_user.followed_users.count + @user.followed_venues.count)
json.lumen_value @other_user.lumens