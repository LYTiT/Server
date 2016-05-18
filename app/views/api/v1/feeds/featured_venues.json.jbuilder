json.cache! @venues, expires_in: 10.minutes, key: @view_cache_key do |json|
  json.activity(@venues) do |venue|
    json.feed_id @feed.id
    json.feed_name @feed.name
    json.feed_color @feed.feed_color
    json.list_creator_id nil

    json.id nil
    json.activity_type "featured_list_venue"
    json.user_id nil
    json.user_name nil
    json.user_phone nil
    json.created_at nil
    json.num_chat_participants nil
    json.latest_chat_time nil

    json.tag_1 venue.tag_1
    json.tag_2 venue.tag_2
    json.tag_3 venue.tag_3
    json.tag_4 venue.tag_4
    json.tag_5 venue.tag_5
    
    json.venue_id venue.id
    json.venue_name venue.name
    json.address venue.address
    json.city venue.city
    json.country venue.country
    json.latitude venue.latitude
    json.longitude venue.longitude
    json.color_rating venue.color_rating
    json.instagram_location_id venue.instagram_location_id

    json.added_note nil

    json.attachment nil

    json.num_likes nil
    json.has_liked nil
    json.topic nil
    json.num_activity_lists nil
  end
end