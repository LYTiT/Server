json.id @other_user.id
json.name @other_user.name
json.is_following @user.following?(@other_user)
json.followers_count @other_user.followers.count
json.following_count 0
json.lumen_value @other_user.lumens