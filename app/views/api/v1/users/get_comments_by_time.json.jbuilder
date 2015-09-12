json.comments(@comments) do |comment|
  json.id comment.id
  json.comment comment.comment
  json.media_type comment.media_type
  json.media_url comment.image_url_1
  json.user_id comment.user_id
  json.user_name comment.user.try(:name)
  json.username_private comment.username_private
  json.user_lumens comment.user.try(:lumens)
  json.venue_id comment.venue_id
  json.venue_name comment.venue.try(:name)
  json.total_views comment.views
  json.created_at comment.time_wrapper
  json.updated_at comment.updated_at
  json.content_origin comment.content_origin
end
json.pagination do 
  json.current_page @comments.current_page
  json.total_pages @comments.total_pages
end