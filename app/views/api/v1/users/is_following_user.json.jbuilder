json.id @other_user.id
json.name @other_user.name
json.is_following @user.following?(@other_user)
json.lumen_value @other_user.lumens