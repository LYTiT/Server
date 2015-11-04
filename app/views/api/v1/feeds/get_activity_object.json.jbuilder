  json.feed_id @activity.feed_id
  json.feed_name @activity.feed.try(:name)
  json.feed_color @activity.feed.try(:feed_color)

  json.id @activity.id
  json.activity_type @activity.activity_type
  json.user_id @activity.user_id
  json.user_name @activity.user.try(:name)
  json.user_phone @activity.user.try(:phone_number)
  json.created_at @activity.created_at
  json.num_chat_participants @activity.num_participants
  json.latest_chat_time @activity.latest_comment_time
  
  json.venue_id @activity.venue_id
  json.venue_name @activity.venue.try(:name)
  json.city @activity.venue.try(:city)
  json.country @activity.venue.try(:country)
  json.latitude @activity.venue.try(:latitude)
  json.longitude @activity.venue.try(:longitude)
  json.color_rating @activity.venue.try(:color_rating)
  json.instagram_location_id @activity.venue.try(:instagram_location_id)

  json.venue_comment_id @activity.venue_comment_id
  json.venue_comment_created_at @activity.venue_comment.try(:created_at)
  json.media_type @activity.venue_comment.try(:media_type)
  json.image_url_1 @activity.venue_comment.try(:image_url_1)
  json.image_url_2 @activity.venue_comment.try(:image_url_2)
  json.image_url_3 @activity.venue_comment.try(:image_url_3)
  json.video_url_1 @activity.venue_comment.try(:video_url_1)
  json.video_url_2 @activity.venue_comment.try(:video_url_2)
  json.video_url_3 @activity.venue_comment.try(:video_url_3)
  json.content_origin @activity.venue_comment.try(:content_origin)
  json.thirdparty_username @activity.venue_comment.try(:thirdparty_username)

  json.num_likes @activity.num_likes
  json.has_liked @activity.liked_by?(@user)
  
  json.topic @activity.message
  json.num_activity_lists @activity.num_lists