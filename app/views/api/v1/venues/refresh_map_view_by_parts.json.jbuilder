json.cache! @view_cache_key, :expires_in => 20.minutes do |json|
    json.array! @venues do |v|
        json.id v.id
        json.name v.name
        json.address v.address
        json.city v.city
        json.country v.country
        json.latitude v.latitude
        json.longitude v.longitude
        json.color_rating v.color_rating
        json.trending_score v.popularity_rank
        json.last_post_time (Time.now - v.latest_posted_comment_time)
        json.instagram_location_id v.instagram_location_id
        
        if v.venue_comment_details["entry_type"] == "lytit_post"
            json.preview_image v.venue_comment_details["lytit_post"]["image_url_1"]
            json.full_image v.venue_comment_details["lytit_post"]["image_url_2"]
            json.full_video v.venue_comment_details["lytit_post"]["video_url_2"]
        end
        if v.venue_comment_details["entry_type"] == "instagram"
            json.preview_image v.venue_comment_details["instagram"]["image_url_1"]
            json.full_image v.venue_comment_details["instagram"]["image_url_2"]
            json.full_video v.venue_comment_details["instagram"]["video_url_2"]        
        end
        json.tag_1 v.trending_tags["tag_1"]
        json.tag_2 v.trending_tags["tag_2"]
        json.tag_3 v.trending_tags["tag_3"]
        json.tag_4 v.trending_tags["tag_4"]
        json.tag_5 v.trending_tags["tag_5"]
        json.venue_categories v.categories.values
    end
end
