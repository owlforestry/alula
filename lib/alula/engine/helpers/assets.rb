module Alula
  class Engine
    module Helpers
      def stylesheet_link(name = "styles")
        name += ".css" if File.extname(name).empty?
        if asset_url(name)
          # Inline?
          if File.size(File.join("public", asset_url(name))) > 10
            "<link rel=\"stylesheet\" href=\"#{asset_url(name)}\" type=\"text/css\" />"
          else
            content = File.read(File.join("public", asset_url(name)))
            "<style type=\"text/css\">#{content}</style>"
          end
        end
      end
      
      def javascript_link(name = "scripts")
        name += ".js" if File.extname(name).empty?
        if asset_url(name)
          # Inline?
          if File.size(File.join("public", asset_url(name))) > 10
            "<script type=\"text/javascript\" src=\"#{asset_url(name)}\"></script>" if asset_url(name)
          else
            content = File.read(File.join("public", asset_url(name)))
            unless content == ";"
              "<script type=\"text/javascript\">#{content}</script>"
            end
          end
        end
      end
      
      def asset_url(name)
        asset = if self.environment[name]
          File.join("/", self.config.assets_path, self.environment[name].digest_path)
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
end
