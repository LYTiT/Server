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
  json.group_1_name comment.groups[0].name
  json.group_1_id comment.groups[0].id
  json.group_2_name comment.groups[1].name
  json.group_2_id comment.group[1].id
  json.group_3_name comment.group[2].name
  json.group_3_id comment.group[2].id
  json.group_4_name comment.group[3].name
  json.group_4_id comment.group[3].id
  json.group_5_name comment.group[4].name
  json.group_5_id comment.group[4].id
end
json.pagination do 
  json.current_page @comments.current_page
  json.total_pages @comments.total_pages
end