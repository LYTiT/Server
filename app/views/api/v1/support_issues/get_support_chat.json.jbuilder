json.array! @issues do |issue|
  json.issue_id issue.id
  json.user_id issue.user_id
  json.user_name issue.user.try(:name)
  json.chat_message issue.message.order("id DESC LIMIT 1")
  json.timestamp message.created_at
end

json.pagination do 
  json.current_page @issues.current_page
  json.total_pages @issues.total_pages
end
