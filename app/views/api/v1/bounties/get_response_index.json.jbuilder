json.position @response.response_index
json.current_page @response.response_page_in_view
json.total_page @bounty.venue_comments.count-1
