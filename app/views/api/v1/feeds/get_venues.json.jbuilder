json.array! @venues do |v|
  json.id v.id
  json.name v.name
  json.formatted_address v.formatted_address
  json.address v.address
  json.city v.city
  json.state v.state
  json.country v.country
  json.postal_code v.postal_code
  json.latitude v.latitude
  json.longitude v.longitude
  json.phone_number v.phone_number
  json.color_rating v.color_rating
  json.compare_type v.type
  json.time_zone_offset v.time_zone_offset
  json.added_by_user FeedVenue.where("feed_id = ? AND venue_id =?", @feed.id, v.id).first.user.try(:name)
  json.num_likes FeedVenue.where("feed_id = ? AND venue_id =?", @feed.id, v.id).first.feed_activities.first.num_likes
  json.did_like Like.where("user_id = ? AND feed_venue_id = ?", FeedVenue.where("feed_id = ? AND venue_id =?", @feed.id, v.id).first.id).any?
end