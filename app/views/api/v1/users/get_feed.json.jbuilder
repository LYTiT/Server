json.comments(@news) do |feed|
    json.id feed.first.id
    json.comment feed.first.comment
    json.media_type feed.first.media_type
    json.media_url feed.first.media_url
    json.user_id feed.first.user_id
    json.user_name feed.first.user.try(:name)
    json.username_private feed.first.username_private
    json.venue_id feed.first.venue_id
    json.venue_name feed.first.venue.try(:name)
    json.viewed feed.first.is_viewed?(@user)
    json.total_views feed.first.views
    json.created_at feed.first.created_at
    json.updated_at feed.first.updated_at
    json.from_user feed.last
end
json.pagination do
  json.current_page @news.current_page
  json.total_pages @news.total_pages
end