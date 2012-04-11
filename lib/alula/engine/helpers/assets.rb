module Alula
  class Engine
    module Helpers
      def stylesheet_link(name = "styles")
        name += ".css" if File.extname(name).empty?
        "<link rel=\"stylesheet\" href=\"#{asset_url(name)}\" type=\"text/css\" />"
      end
      
      def javascript_link(name = "scripts")
        name += ".js" if File.extname(name).empty?
        "<script type=\"text/javascript\" src=\"#{asset_url(name)}\"></script>"
      end
      
      def asset_url(name)
        asset = if self.environment[name]
          File.join(self.config.assets_path, self.environment[name].digest_path)
        elsif /^(?<prefix>(images|thumbnails))\/(?<name>.+)/ =~ name
          # Try to find attachment
          if self.attachments[name]
            asset_url(File.join(prefix, self.attachments[name]))
          end
        end
        asset
      end
    end
  end
end
