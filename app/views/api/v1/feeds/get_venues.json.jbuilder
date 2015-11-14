json.array! @added_venue_activities do |added_venue_activity|
  json.venue_id added_venue_activity.venue.id  
  json.activity_id added_venue_activity.id
  json.name added_venue_activity.venue.name
  json.formatted_address added_venue_activity.venue.formatted_address
  json.address added_venue_activity.venue.address
  json.city added_venue_activity.venue.city
  json.state added_venue_activity.venue.state
  json.country added_venue_activity.venue.country
  json.postal_code added_venue_activity.venue.postal_code
  json.latitude added_venue_activity.venue.latitude
  json.longitude added_venue_activity.venue.longitude
  json.phone_number added_venue_activity.venue.phone_number
  json.color_rating added_venue_activity.venue.color_rating
  json.time_zone_offset added_venue_activity.venue.time_zone_offset

  json.added_by_user added_venue_activity.user.try(:name)
  json.num_likes added_venue_activity.num_likes
  json.feed_venue_id added_venue_activity.feed_venue_id
  json.added_note added_venue_activity.feed_venue.description

  json.did_like @user.likes.where("activity_id = ?", added_venue_activity.id).first.present?
end