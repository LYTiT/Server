json.comments(@comments) do |comment|
  json.id VenueComment.implicit_id(comment)
  json.instagram_id VenueComment.implicit_instagram_id(comment)
  json.instagram_location_id VenueComment.implicit_instagram_location_id(comment)
  json.latitude VenueComment.implicit_venue_latitude(comment)
  json.longitude VenueComment.implicit_venue_longitude(comment)
  json.media_type VenueComment.implicit_media_type(comment)
  json.media_url VenueComment.implicit_image_url_2(comment)
  json.image_url_1 VenueComment.implicit_image_url_1(comment)
  json.image_url_2 VenueComment.implicit_image_url_2(comment)
  json.image_url_3 VenueComment.implicit_image_url_3(comment)
  json.video_url_1 VenueComment.implicit_video_url_1(comment)
  json.video_url_2 VenueComment.implicit_video_url_2(comment)
  json.video_url_3 VenueComment.implicit_video_url_3(comment)
  json.venue_id VenueComment.implicit_venue_id(comment)
  json.venue_name VenueComment.implicit_venue_name(comment)
  json.created_at VenueComment.implicit_created_at(comment)
  json.content_origin VenueComment.implicit_content_origin(comment)
  json.thirdparty_username VenueComment.thirdparty_username(comment)
  json.total_pages @comments.total_pages
end
json.pagination do
  json.venue_id @venue.try(:id)
  json.current_page @comments.current_page
  json.total_pages @comments.total_pages
end