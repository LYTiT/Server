json.set! :user do
  json.set! :id, @host.id
  json.set! :name, @host.name
end

json.set! :group do
  json.set! :id, @group.id
  json.set! :name, @group.name
end