json.comments(@questions) do |question|
  json.question question.question
  json.user_id  question.user_id
  json.user_name question.user.name
  json.num_comments question.num_comments
  json.created_at question.created_at
end