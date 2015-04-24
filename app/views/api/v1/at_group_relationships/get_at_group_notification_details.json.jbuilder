json.set! :venue_comment do
  json.set! :id, @venue_comment.id
  json.set! :comment, @venue_comment.comment
  json.set! :media_type, @venue_comment.media_type
  json.set! :media_url, @venue_comment.media_url
  json.set! :user_id, @venue_comment.user_id
  json.set! :user_name, @venue_comment.user.try(:name)
  json.set! :username_private, @venue_comment.username_private
  json.set! :venue_id, @venue_comment.venue_id
  json.set! :venue_name, @venue_comment.try(:name)
  json.set! :total_views, @venue_comment.total_views
  json.set! :created_at, @venue_comment.created_at
  json.set! :updated_at, @venue_comment.updated_at
end

json.set! :group do
  json.set! :id, @group.id
  json.set! :name, @group.name
end