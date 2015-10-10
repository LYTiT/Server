json.activity(@activities) do |activity|
  json.id activity.id
  json.type activity.activity_type
  json.user_id activity.user_id
  json.user_name activity.user.name
  json.user_phone activity.user.phone_number
  json.created_at activity.created_at

  json.venue_id activity.venue_id
  json.venue_name activity.venue.try(:name)
  json.venue_latitude activity.venue.try(:latitude)
  json.venue_longitude activity.venue.try(:longitude)
  json.color_rating activity.venue.try(:color_rating)

  json.venue_comment_id activity.feed_share.try(:venue_comment_id)
  json.venue_comment_created_at activity.feed_share.try(:venue_comment).try(:created_at)
  json.media_type activity.feed_share.venue_comment.media_type
  json.image_url_1 activity.feed_share.try(:venue_comment).try(:image_url_1)
  json.image_url_2 activity.feed_share.try(:venue_comment).try(:image_url_2)
  json.image_url_3 activity.feed_share.try(:venue_comment).try(:image_url_3)
  json.video_url_1 activity.feed_share.try(:venue_comment).try(:video_url_1)
  json.video_url_2 activity.feed_share.try(:venue_comment).try(:video_url_2)
  json.video_url_3 activity.feed_share.try(:venue_comment).try(:video_url_3)
  json.content_origin activiy.feed_share.try(:venue_comment).try(:content_origin)
  json.thirdparty_username activiy.feed_share.try(:venue_comment).try(:thirdparty_username)
  
  json.topic activity.feed_topic.try(:message)
end
json.pagination do 
  json.current_page @activities.current_page
  json.total_pages @activities.total_pages
end