json.id @user.id
json.name @user.name
json.num_likes @user.num_likes
json.set_password @user.password.present?
json.phone_number @user.phone_number
json.country_code @user.country_code
json.support_issue_id @user.support_issues.first.id
json.lytit_admin @user.is_admin?
json.email @user.email
json.authentication_token @user.authentication_token
json.aws_auth S3Detail.new(@user.email_with_id).encrypt rescue ''
json.registered @user.registered