json.id @user.id
json.name @user.name
json.profile_image_url @user.profile_image_url
json.description @user.description
json.fb_id @user.facebook_id
json.fb_name @user.facebook_name
json.num_likes @user.num_likes
json.phone_number @user.phone_number
json.country_code @user.country_code
json.lytit_admin @user.is_admin?
json.email @user.email
json.authentication_token @user.authentication_token
json.aws_auth S3Detail.new(@user.email_with_id).encrypt rescue ''
json.registered @user.registered
json.instagram_user_name @user.instagram_auth_tokens.first.try(:instagram_user_name)
json.instagram_user_id @user.instagram_auth_tokens.first.try(:instagram_user_id)
json.instagram_token_expired @user.instagram_auth_tokens.first.try(:is_valid)