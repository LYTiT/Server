json.array! @contexts do |context|
  json.context context.meta
  json.relevance_score context.update_and_return_relevance_score
end