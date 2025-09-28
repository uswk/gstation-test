json.array!(@users) do |user|
  json.extract! user, :user_id, :user_name, :password
  json.url user_url(user, format: :json)
end