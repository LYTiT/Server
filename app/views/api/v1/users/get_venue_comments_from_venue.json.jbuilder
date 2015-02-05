json.comments(@comments) do |comment|
	json.id comment.first.id
	json.comment comment.first.comment
	json.media_type comment.first.media_type
	json.media_url comment.first.media_url
	json.user_id comment.first.user_id
	json.user_name comment.first.user.try(:name)
	json.username_private comment.first.username_private
	json.venue_id comment.first.venue_id
	json.venue_name comment.first.venue.try(:name)
	json.viewed comment.first.is_viewed?(@user)
	json.total_views comment.first.views
	json.created_at comment.first.created_at
	json.updated_at comment.first.updated_at
	json.group_1_name comment.first.groups[0].try(:name)
	json.group_1_id comment.first.groups[0].try(:id)
	json.group_2_name comment.first.groups[1].try(:name)
	json.group_2_id comment.first.groups[1].try(:id)
	json.group_3_name comment.first.groups[2].try(:name)
	json.group_3_id comment.first.groups[2].try(:id)
	json.group_4_name comment.first.groups[3].try(:name)
	json.group_4_id comment.first.groups[3].try(:id)
	json.group_5_name comment.first.groups[4].try(:name)
	json.group_5_id comment.first.groups[4].try(:id)
	json.from_user comment.last
end
json.pagination do
  json.current_page @comments.current_page
  json.total_pages @comments.total_pages
end