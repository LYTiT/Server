json.comments(@question_comments) do |question_comment|
  json.chat_message question_comment.comment
  json.user_id  question_comment.user_id
  json.user_name  question_comment.user.name
  json.created_at question_comment.created_at
end