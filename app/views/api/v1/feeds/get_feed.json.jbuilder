json.id @feed.id
json.name @feed.name
json.open @feed.open
json.creator @feed.user
json.list_creator_fb_name @feed.user.facebook_name
json.list_creator_fb_id @feed.user.facebook_id
json.num_venues @feed.num_venues
json.num_users @feed.num_users
json.num_moments @feed.num_moments
json.has_added @feed.feed_users.where("user_id = ?", @user.id).first.present?
json.feed_color @feed.feed_color
json.list_description @feed.description
json.subscribed @feed.feed_users.where("user_id = ?", @user.id).first.try(:is_subscribed)
json.private_list @feed.is_private?

