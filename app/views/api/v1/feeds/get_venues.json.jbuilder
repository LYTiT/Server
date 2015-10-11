json.array! @venues do |v|
  json.id v.id
  json.feed_activity_id v.feed_activities.where("feed_id = ?", @feed.id).first.try(:id)
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
  json.added_by_user v.feed_activities.where("feed_id = ?", @feed.id).first.try(:user).try(:name)
  json.num_likes v.feed_activities.where("feed_id = ?", @feed.id).first.try(:num_likes)
  json.description v.feed_venues.where("feed_id = ?", @feed.id).first.try(:description)
  json.did_like @user.likes.where("feed_activity_id = ?", v.feed_activities.where("feed_id = ?", @feed.id).first.id).any?
end