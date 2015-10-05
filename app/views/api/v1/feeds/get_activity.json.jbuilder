json.activity(@activities) do |activity|
  json.list_name @feed.name
  json.id activity.id
  json.comment activity.venue_comment.try(:comment)
  json.media_type activity.venue_comment.try(:media_type)
  json.media_url activity.venue_comment.try(:image_url_2)
  json.venue_comment_id activity.venue_comment_id
  json.image_url_1 activity.venue_comment.try(:image_url_1)
  json.image_url_2 activity.venue_comment.try(:image_url_2)
  json.image_url_3 activity.venue_comment.try(:image_url_3)
  json.video_url_1 activity.venue_comment.try(:video_url_1)
  json.video_url_2 activity.venue_comment.try(:video_url_2)
  json.video_url_3 activity.venue_comment.try(:video_url_2)
  json.user_id activity.venue_comment.try(:user_id)
  json.user_name activity.venue_comment.try(:user).try(:name)
  json.venue_id activity.venue_comment.try(:venue_id)
  json.venue_name activity.venue_comment.try(:venue).try(:name)
  json.created_at activity.implicit_created_at
  json.updated_at activity.venue_comment.try(:updated_at)
  json.content_origin activity.venue_comment.try(:content_origin)
  json.thirdparty_username activity.venue_comment.try(:thirdparty_username)

  json.activity_type activity.activity_type
  
  json.action_user_id activity.implicit_action_user.try(:id)
  json.action_user_name activity.implicit_action_user.try(:name)
  json.passive_user_id activity.like.try(:liked_id)
  json.passive_user_name activity.like.try(:liked).try(:name)
  json.liked_venue activity.like.try(:feed_venue).try(:venue)
  json.num_likes activity.num_likes
  json.did_like activity.did_like?(@user)

  json.added_venue activity.feed_venue.try(:venue)

end
json.pagination do 
  json.current_page @activities.current_page
  json.total_pages @activities.total_pages
end