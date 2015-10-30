json.cache_collection! @contexts, expires_in: 3.minutes, key: @key do |context|
  json.meta context.meta  
end