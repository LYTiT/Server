json.activity(@activities) do |activity|
  json.feed_id Feed.joins(:feed_venues, :feed_users).where("feed_venues.venue_id = ? AND feed_users.user_id = ?", activity["id"], @user.id).order("feed_users.interest_score DESC").first.id
  json.feed_name Feed.joins(:feed_venues, :feed_users).where("feed_venues.venue_id = ? AND feed_users.user_id = ?", activity["id"], @user.id).order("feed_users.interest_score DESC").first.name
  json.feed_color Feed.joins(:feed_venues, :feed_users).where("feed_venues.venue_id = ? AND feed_users.user_id = ?", activity["id"], @user.id).order("feed_users.interest_score DESC").first.feed_color
  json.list_creator_id nil

  json.id nil
  json.activity_type "featured_list_venue"
  json.user_id nil
  json.user_name nil
  json.user_phone nil
  json.created_at nil
  json.num_chat_participants nil
  json.latest_chat_time nil

  json.tag_1 MetaData.where("venue_id = ?", activity["id"]).order("relevance_score DESC").limit(1).offset(1).first.meta
  json.tag_2 MetaData.where("venue_id = ?", activity["id"]).order("relevance_score DESC").limit(1).offset(2).first.meta
  json.tag_3 MetaData.where("venue_id = ?", activity["id"]).order("relevance_score DESC").limit(1).offset(3).first.meta
  json.tag_4 MetaData.where("venue_id = ?", activity["id"]).order("relevance_score DESC").limit(1).offset(4).first.meta
  json.tag_5 MetaData.where("venue_id = ?", activity["id"]).order("relevance_score DESC").limit(1).offset(5).first.meta
  
  json.venue_id activity["id"]
  json.venue_name activity["name"]
  json.address activity["address"]
  json.city activity["city"]
  json.country activity["country"]
  json.latitude activity["latitude"]
  json.longitude activity["longitude"]
  json.color_rating activity["color_rating"]
  json.instagram_location_id activity["instagram_location_id"]

  json.added_note nil

  json.attachment Activity.select_content_for_featured_venue_activity(activity, @user.id, nil, nil, nil)

  json.num_likes nil
  json.has_liked nil
  json.topic nil
  json.num_activity_lists nil
end