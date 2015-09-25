json.comments(@posts) do |post|
  json.id VenueComment.implicit_id(post)
  json.latitude post.try(:location).try(:latitude)
  json.longitude post.try(:location).try(:longitude)
  json.media_type VenueComment.implicit_media_type(post)
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
  json.current_page @posts.current_page
  json.total_pages @posts.total_pages
end