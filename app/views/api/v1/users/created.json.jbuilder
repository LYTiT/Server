json.id @user.id
json.name @user.name
json.num_likes @user.num_likes
json.phone_number @user.phone_number
json.country_code @user.country_code
json.lytit_admin @user.is_admin?
json.email @user.email
json.authentication_token @user.authentication_token
json.aws_auth S3Detail.new(@user.email_with_id).encrypt rescue ''
json.registered @user.registered