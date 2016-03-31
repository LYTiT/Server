json.comments(@comments) do |comment|
    json.id comment.id
    json.instagram_id nil
    json.instagram_location_id nil
    json.media_type comment.media_type
    json.media_dimensions comment.media_dimensions
    json.media_url nil
    json.image_url_1 comment.image_url_1
    json.image_url_2 comment.image_url_2
    json.image_url_3 comment.image_url_3
    json.video_url_1 comment.video_url_1
    json.video_url_2 comment.video_url_2
    json.video_url_3 comment.video_url_3
    json.venue_id comment.venue_id
    json.created_at comment.created_at
    json.content_origin 'lytit'
    json.thirdparty_username nil
    json.geo_views comment.geo_views
    json.num_bolts comment.views
end
