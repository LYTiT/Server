json.array! @users do |user|
	json.id user.id
	json.name user.name
	json.fb_id user.facebook_id
	json.fb_name user.facebook_name
	json.phone_number user.phone_number
	json.num_lists	user.feed_users.count
	json.num_likes user.num_likes
	json.is_list_member user.feed_users.where("feed_id = ?", @feed.id).first.present?
	json.invited_to_list  user.received_feed_invitations.where("feed_id = ?", @feed.id).first.present?
end