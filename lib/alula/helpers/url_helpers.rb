module Alula
  module Helpers
    def link_to(content, url, attributes = {})
      tag = "<a"
      tag += " href=\"#{url}\""
      attributes.each do |name, value|
        tag += " #{name}=\"#{value}\""
      end
      tag += ">#{content}</a>"
    end
  end
end