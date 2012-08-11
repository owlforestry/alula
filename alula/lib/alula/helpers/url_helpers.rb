module Alula
  module Helpers
    def url_for(name)
      File.join(self.site.config.url, name)
    end
    
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