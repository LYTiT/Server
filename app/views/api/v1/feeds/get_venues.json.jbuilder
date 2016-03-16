json.array! @feed_venues do |feed_venue|
  json.venue_id feed_venue.venue.id  
  json.activity_id feed_venue.id
  json.name feed_venue.venue.name
  json.formatted_address feed_venue.venue.formatted_address
  json.address feed_venue.venue.address
  json.city feed_venue.venue.city
  json.state feed_venue.venue.state
  json.country feed_venue.venue.country
  json.postal_code feed_venue.venue.postal_code
  json.latitude feed_venue.venue.latitude
  json.longitude feed_venue.venue.longitude
  json.phone_number feed_venue.venue.phone_number
  json.color_rating feed_venue.venue.rating
  json.time_zone_offset feed_venue.venue.time_zone_offset

  json.added_by_user feed_venue.user.try(:name)
  json.num_likes feed_venue.activity.try(:num_likes)
  json.feed_venue_id feed_venue.id
  json.added_note feed_venue.description

  json.did_like @user.likes.where("activity_id = ?", feed_venue.activity.try(:id)).first.present?
end