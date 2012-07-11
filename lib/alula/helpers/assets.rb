module Alula
  module Helpers
    def stylesheet_link(name = "style")
      name += ".css" if File.extname(name).empty?
      if asset_url(name)
        # Inline?
        if self.environment[name].pathname.size > 10
          "<link rel=\"stylesheet\" href=\"#{asset_url(name)}\" type=\"text/css\" />"
        else
          content = self.environment[name].pathname.read
          "<style type=\"text/css\">#{content}</style>"
        end
      end
    end
    
    def asset_path(name)
      return if name.nil?

      if self.environment[name]
        # Get asset URL
        asset_path = File.join("assets", self.environment[name].digest_path)
      end
    end
    
    def asset_url(name)
      return if name.nil?

      if self.environment[name]
        self.site.cdn.url_for(asset_path(name), file: self.environment[name].pathname.to_s)
      end
    end
  end
end