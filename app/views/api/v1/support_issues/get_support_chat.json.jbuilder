json.chat_messages(@messages) do |message|
  json.id message.id
  json.issue_id message.support_issue_id
  json.user_id message.support_issue.user_id
  json.user_name message.support_issue.user.try(:name)
  json.chat_message message.message
  json.timestamp message.created_at
end

json.pagination do 
  json.current_page @messages.current_page
  json.total_pages @messages.total_pages
end