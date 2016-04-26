json.array! @feeds do |feed|
	json.id feed.id
	json.name feed.name
	json.open feed.open
	json.creator feed.user.try(:partial)
	json.list_creator_fb_name feed.user.try(:facebook_name)
	json.list_creator_fb_id feed.user.try(:facebook_id)
	json.num_venues feed.num_venues
	json.num_users feed.num_users
	json.num_moments feed.num_moments
	json.feed_color feed.feed_color
	json.list_description feed.description
	json.is_private feed.is_private
	json.preview_image_url feed.preview_image_url
	json.cover_image_url feed.cover_image_url
	json.has_added feed.feed_users.where("user_id = ?", @user.id).first.present?
end