json.array! @feed_venues do |feed_venue|
  json.venue_id feed_venue.venue_details["id"]
  json.activity_id feed_venue.id
  json.name feed_venue.venue_details["name"]
  json.address feed_venue.venue_details["address"]
  json.city feed_venue.venue_details["city"]
  json.state feed_venue.venue_details["state"]
  json.country feed_venue.venue_details["country"]
  json.postal_code feed_venue.venue_details["postal_code"]
  json.latitude feed_venue.venue_details["latitude"]
  json.longitude feed_venue.venue_details["longitude"]

  json.added_by_user feed_venue.user_details["name"]
  json.feed_venue_id feed_venue.feed_venue_details["id"]
  json.added_note feed_venue.feed_venue_details["added_note"]

  json.did_like @user.likes.where("activity_id = ?", feed_venue.id).first.present?
end