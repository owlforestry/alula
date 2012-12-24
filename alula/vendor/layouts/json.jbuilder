json.meta do
  json.title site.title
  json.description site.tagline
  json.origin site.url
  json.updated Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
  json.generator "Alula #{Alula::VERSION::STRING}"
end

json.items item.posts do |post|
  json.title post.title
  json.content post.body
  json.date post.date.strftime("%a, %d %b %Y %H:%M:%S %z")
  json.url "#{site.url}#{post.url}"
end
