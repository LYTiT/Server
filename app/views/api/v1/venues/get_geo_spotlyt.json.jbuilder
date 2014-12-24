json.array! @spotlyts do |comment|
  json.id comment.id
  json.comment comment.comment
  json.media_type comment.media_type
  json.media_url comment.media_url
  json.user_id comment.user_id
  json.user_name comment.user.try(:name)
  json.username_private comment.username_private
  json.venue_id comment.venue_id
  json.venue_name comment.venue.try(:name)
  json.total_views comment.total_views
  json.created_at comment.created_at
  json.group_1_name comment.groups[0].try(:name)
  json.group_1_id comment.groups[0].try(:id)
  json.group_2_name comment.groups[1].try(:name)
  json.group_2_id comment.groups[1].try(:id)
  json.group_3_name comment.groups[2].try(:name)
  json.group_3_id comment.groups[2].try(:id)
  json.group_4_name comment.groups[3].try(:name)
  json.group_4_id comment.groups[3].try(:id)
  json.group_5_name comment.groups[4].try(:name)
  json.group_5_id comment.groups[4].try(:id)
end