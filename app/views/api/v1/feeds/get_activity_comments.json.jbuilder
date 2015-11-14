json.activity_comments(@activity_comments) do |activity_comment|
  json.id activity_comment.id
  json.user_id activity_comment.user_id
  json.user_name activity_comment.user.name
  json.user_phone activity_comment.user.phone_number
  json.chat_message activity_comment.comment
  json.created_at activity_comment.created_at
end