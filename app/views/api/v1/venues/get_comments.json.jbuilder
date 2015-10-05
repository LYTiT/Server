json.comments(@comments) do |comment|
  json.id VenueComment.implicit_id(post)
  json.latitude VenueComment.implicit_venue_latitude(post)
  json.longitude VenueComment.implicit_venue_longitude(post)
  json.media_type VenueComment.implicit_media_type(post)
  json.media_url VenueComment.implicit_image_url_2(post)
  json.image_url_1 VenueComment.implicit_image_url_1(post)
  json.image_url_2 VenueComment.implicit_image_url_2(post)
  json.image_url_3 VenueComment.implicit_image_url_3(post)
  json.video_url_1 VenueComment.implicit_video_url_1(post)
  json.video_url_2 VenueComment.implicit_video_url_2(post)
  json.video_url_3 VenueComment.implicit_video_url_3(post)
  json.venue_id VenueComment.implicit_venue_id(post)
  json.venue_name VenueComment.implicit_venue_name(post)
  json.created_at VenueComment.implicit_created_at(post)
  json.content_origin VenueComment.implicit_content_origin(post)
  json.thirdparty_username VenueComment.thirdparty_username(post)
end
json.pagination do 
  json.current_page @comments.current_page
  json.total_pages @comments.total_pages
end