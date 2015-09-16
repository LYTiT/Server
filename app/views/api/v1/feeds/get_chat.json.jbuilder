json.chat_messages(@messages) do |message|
  json.id message.id
  json.user_id message.user_id
  json.user_name message.user.try(:name)
  json.user_phone message.user.try(:phone_number)
  json.chat_message message.message
  json.venue_comment_id message.venue_comment.try(:id)
  json.media_type message.venue_comment.try(:media_type)
  json.media_url message.venue_comment.try(:lowest_resolution_image_avaliable)
  json.timestamp message.created_at
end

json.pagination do 
  json.current_page @messages.current_page
  json.total_pages @messages.total_pages
end