module Alula
  module Helpers
    def stylesheet_link(name = "style")
      name += ".css" if File.extname(name).empty?
      if asset_url(name)
        # Inline?
        if File.size(File.join(self.storage.path(:public), asset_url(name))) > 10
          "<link rel=\"stylesheet\" href=\"#{asset_url(name)}\" type=\"text/css\" />"
        else
          content = File.read(self.storage.path(:public), asset_url(name))
          "<style type=\"text/css\">#{content}</style>"
        end
      end
    end
    
    def asset_url(name)
      asset = if self.environment[name]
        File.join("/", "assets", self.environment[name].digest_path)
      elsif /^(?<prefix>(images|thumbnails))\/(?<name>.+)/ =~ name
        # Try to find attachment
        if self.attachments[name.downcase]
          asset_url(File.join(prefix, self.attachments[name.downcase]))
        end
      end
      asset
    end
    
  end
end