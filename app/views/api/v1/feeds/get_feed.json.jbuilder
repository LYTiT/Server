json.id @feed.id
json.name @feed.name
json.creator @feed.user
json.num_venues @feed.num_venues
json.num_users @feed.num_users
json.has_added @feed.has_added?(@user)
json.feed_color @feed.feed_color
json.list_description @feed.description
json.subscribed @feed.subscribed?(@user)
json.users_can_add_places @feed.is_open?
json.private_list @feed.is_private?
