json.comments(@comments) do |comment|
  json.id comment.id
  json.comment comment.comment
  json.media_type comment.media_type
  json.media_url comment.media_url
  json.user_id comment.user_id
  json.user_name comment.user.try(:name)
  json.username_private comment.username_private
  json.venue_id comment.venue_id
  json.venue_name comment.venue.try(:name)
  json.viewed comment.is_viewed?(@user)
  json.total_views comment.views
  json.created_at comment.created_at
  json.updated_at comment.updated_at
end
json.pagination do 
  json.current_page @comments.current_page
  json.total_pages @comments.total_pages
  json.total_posts @bounty.venue_comments.count-1
end