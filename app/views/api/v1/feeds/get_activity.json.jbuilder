json.activity(@activities) do |activity|
  json.list_name @feed.name
  json.id activity.try(:venue_comment).try(:venue_comment.id)
  json.comment activity.try(:venue_comment).try(:comment)
  json.media_type activity.try(:venue_comment).try(:media_type)
  json.media_url activity.try(:venue_comment).try(:image_url_2)
  json.image_url_1 activity.try(:venue_comment).try(:image_url_1)
  json.image_url_2 activity.try(:venue_comment).try(:image_url_2)
  json.image_url_3 activity.try(:venue_comment).try(:image_url_3)
  json.video_url_1 activity.try(:venue_comment).try(:video_url_1)
  json.video_url_2 activity.try(:venue_comment).try(:video_url_2)
  json.video_url_3 activity.try(:venue_comment).try(:video_url_2)
  json.user_id activity.try(:venue_comment).try(:user_id)
  json.user_name activity.try(:venue_comment).try(:user.try(:name)
  json.username_private activity.try(:venue_comment).try(:username_private)
  json.venue_id activity.try(:venue_comment).try(:venue_id)
  json.venue_name activity.try(:venue_comment).try(:venue.try(:name)
  json.created_at activity.try(:venue_comment).try(:time_wrapper)
  json.updated_at activity.try(:venue_comment).try(:updated_at)
  json.content_origin activity.try(:venue_comment).try(:content_origin)
  json.thirdparty_username activity.try(:venue_comment).try(:thirdparty_username)

  json.activity_type activity.activity_type
  
  json.action_user_id activity.try(:like).try(:liker_id)
  json.action_user_name activity.try(:like).try(:liker).try(:name)
  json.passive_user_id activity.try(:like).try(:liked_id)
  json.passive_user_name activity.try(:like).try(:liked).try(:name)
  json.num_likes activity.num_likes
  json.did_like activity.did_like?(@user)

  json.added_venue activity.try(:feed_venue).try(:venue)

  json.liked_venue activity.try(:like).(:feed_venue).try(:venue)

end
json.pagination do 
  json.current_page @activities.current_page
  json.total_pages @activities.total_pages
end