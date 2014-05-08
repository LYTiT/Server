json.array! @user.venue_comments do |comment|
  json.id comment.id
  json.comment comment.comment
  json.media_type comment.media_type
  json.media_url comment.media_url
  json.user_id comment.user_id
  json.user_name comment.user.try(:name)
  json.venue_id comment.venue_id
  json.venue_name comment.venue.try(:name)
  json.created_at comment.created_at
  json.updated_at comment.updated_at
end
