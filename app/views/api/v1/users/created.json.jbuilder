json.id @user.id
json.name @user.name
json.set_unpassword @user.password.nil?
json.user_phone @user.phone_number
json.user_phone_country @user.country_code
json.support_issue_id @user.support_issues.first.id
json.lytit_admin @user.is_admin?
json.email @user.email
json.authentication_token @user.authentication_token
json.aws_auth S3Detail.new(@user.email_with_id).encrypt rescue ''
json.lumen_value @user.lumens
json.registered @user.registered