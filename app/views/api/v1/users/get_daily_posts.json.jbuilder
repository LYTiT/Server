json.comments(@comments) do |comment|
    json.id comment.id
    json.instagram_id nil
    json.instagram_location_id nil
    json.media_type comment.lytit_post["media_type"]
    json.media_dimensions comment.lytit_post["media_dimensions"]
    json.media_url nil
    json.image_url_1 comment.lytit_post["image_url_1"]
    json.image_url_2 comment.lytit_post["image_url_2"]
    json.image_url_3 comment.lytit_post["image_url_3"]
    json.video_url_1 comment.lytit_post["video_url_1"]
    json.video_url_2 comment.lytit_post["video_url_2"]
    json.video_url_3 comment.lytit_post["video_url_3"]
    json.venue_id comment.venue_details["id"]
    json.venue_name comment.venue_details["name"]
    json.latitude comment.venue_details["latitdue"]
    json.longitude comment.venue_details["longitude"]
    json.created_at comment.created_at
    json.content_origin 'lytit'
    json.geo_views comment.geo_views
    json.num_bolts comment.views
end
