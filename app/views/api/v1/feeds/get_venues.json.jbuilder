json.array! @feed_venue_activities do |feed_venue_activity|
  json.venue_id feed_venue_activity.venue_details["id"]
  json.activity_id feed_venue_activity.id
  json.name feed_venue_activity.venue_details["name"]
  json.address feed_venue_activity.venue_details["address"]
  json.city feed_venue_activity.venue_details["city"]
  json.state feed_venue_activity.venue_details["state"]
  json.country feed_venue_activity.venue_details["country"]
  json.postal_code feed_venue_activity.venue_details["postal_code"]
  json.latitude feed_venue_activity.venue_details["latitude"]
  json.longitude feed_venue_activity.venue_details["longitude"]

  json.added_by_user feed_venue_activity.user_details["name"]
  json.added_by feed_venue_activity.user_details["id"]
  json.feed_venue_id feed_venue_activity.feed_venue_details["id"]
  json.added_note feed_venue_activity.feed_venue_details["added_note"]

  json.did_upvote feed_venue_activity.upvote_user_ids.include?(@user.id)
  json.num_upvotes feed_venue_activity.feed_venue.num_upvotes
  json.num_comments
end