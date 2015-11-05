json.id @feed.id
json.name @feed.name
json.creator @feed.user
json.num_venues @feed.num_venues
json.num_users @feed.num_users
json.has_added @feed.users.where("users.id = ?", @user.id).any?
json.feed_color @feed.feed_color
json.list_description @feed.description
json.subscribed @feed.is_subscribed?(@user)
json.private_list @feed.is_private?
