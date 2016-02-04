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

    json.tag_1 MetaData.where("venue_id = ?", venue.id).order("relevance_score DESC").limit(1).offset(1).first.meta
    json.tag_2 MetaData.where("venue_id = ?", venue.id).order("relevance_score DESC").limit(1).offset(2).first.meta
    json.tag_3 MetaData.where("venue_id = ?", venue.id).order("relevance_score DESC").limit(1).offset(3).first.meta
    json.tag_4 MetaData.where("venue_id = ?", venue.id).order("relevance_score DESC").limit(1).offset(4).first.meta
    json.tag_5 MetaData.where("venue_id = ?", venue.id).order("relevance_score DESC").limit(1).offset(5).first.meta
    
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

    json.attachment Activity.select_content_for_featured_venue_activity(venue, @user.id, @feed.id, @feed.name, @feed.feed_color)

    json.num_likes nil
    json.has_liked nil
    json.topic nil
    json.num_activity_lists nil
  end
end