json.set! :venue_comment do
  json.set! :id, @venue_comment.id
  json.set! :comment, @venue_comment.name
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
  json.set! :group_1_name, @venue_comment.groups[0].try(:name)
  json.set! :group_1_id, @venue_comment.groups[0].try(:id)
  json.set! :group_2_name, @venue_comment.groups[1].try(:name)
  json.set! :group_2_id, @venue_comment.groups[1].try(:id)
  json.set! :group_3_name, @venue_comment.groups[2].try(:name)
  json.set! :group_3_id, @venue_comment.groups[2].try(:id)
  json.set! :group_4_name, @venue_comment.groups[3].try(:name)
  json.set! :group_4_id, @venue_comment.groups[3].try(:id)
  json.set! :group_5_name, @venue_comment.groups[4].try(:name)
  json.set! :group_5_id, @venue_comment.groups[4].try(:id)
end

json.set! :group do
  json.set! :id, @group.id
  json.set! :name, @group.name
end