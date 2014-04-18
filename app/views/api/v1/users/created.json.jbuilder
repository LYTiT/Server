json.id @user.id
json.name @user.name
json.email @user.email
json.authentication_token @user.authentication_token
json.aws_auth S3Detail.new(@user.email_with_id).encrypt
