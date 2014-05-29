json.id @user.id
json.name @user.name
json.email @user.email
json.authentication_token @user.authentication_token
json.aws_auth S3Detail.new(@user.email_with_id).encrypt rescue ''
json.notify_events_added_to_groups @user.notify_events_added_to_groups
json.notify_location_added_to_groups @user.notify_location_added_to_groups
json.notify_venue_added_to_groups @user.notify_venue_added_to_groups
