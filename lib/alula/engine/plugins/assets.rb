require 'mini_exiftool'

module Alula
  class Engine
    class Plugins
      class Video < Tag
        register :video
        
        def self.install(options)
          @@options = options
        end
        
        def prepare(markup, tokens)
          /(?<src>(?:https?:\/\/|\/|\S+\/)[^"]+)(?:"|')?/ =~ markup
          @name = src.strip
        end
        
        def content(context)
          # Try to find all possible variant of video
          exif = MiniExiftool.new File.join("public", sources.first)
          tag = "<video"
          tag += " controls"
          tag += " width=\"#{exif.imagewidth}\" height=\"#{exif.imageheight}\" poster=\"#{poster}\" preload=\"none\">\n"
          
          sources.each do |src|
            exif = MiniExiftool.new File.join("public", src)
            hd = (exif.imageheight >= 720 or exif.imagewidth >= 720)
            tag << "  <source src=\"#{src}\" #{hd ? "data-quality=\"hd\"" : ""} />\n"
          end
          tag << "</video>\n"
        end
        
        private
        def asset
          @asset ||= context.attachments[@name]
        end
        
        def sources
          @sources ||= begin
            sources = []
            ["-hd.mp4", ".mp4", "-mobile-hd.mp4", "-mobile.mp4", ".webm", ".ogg"].each do |variant|
              # Resolve name
              sources << context.asset_url(File.join("images", "#{asset}#{variant}"))
            end
            sources
          end
        end
        
        def poster
          context.asset_url(File.join("thumbnails", "#{asset}.png"))
        end
      end

      class Image < Tag
        register :image
        
        attr_accessor :prefix, :name
        
        
        def self.install(options)
          @@options = options
        end
        
        def prepare(markup, tokens)
          /(?<src>(?:https?:\/\/|\/|\S+\/)\S+)(?<title>\s+.+)?/ =~ markup
          /(?:"|')(?<title>[^"']+)?(?:"|')\s+(?:"|')(?<alt>[^"']+)?(?:"|')/ =~ title
          
          self.name = src
          @title = title || ""
          @alt = alt || ""
        end
        
        def content(context)
          imagetag(self.name)
        end
        
        private
        def imagetag(name, prefix = nil)
          tag = "<img"
          tag += " alt=\"#{@alt}\"" if @alt
          tag += " title=\"#{@title}\"" if @title
          if context.config.images["lazyload"]
            tag += " src=\"#{context.asset_url("grey.gif")}\""
            tag += " data-original=\"#{source(name, prefix)}\""
            tag += " data-retina=\"#{retina(name, prefix)}\"" if context.config.images["retina"] and retina(name, prefix)
            tag += " width=\"#{width(name, prefix)}\" height=\"#{height(name, prefix)}\""
          end
          tag += " />"
        end
        
        def source(name, prefix)
          if name[/^http/]
            name
          else
            if prefix
              context.asset_url(File.join(prefix, name))
            else
              context.asset_url(name)
            end
          end
        end
        
        def retina(name, prefix)
          ext = File.extname(name)
          source(name.gsub(/#{ext}$/, "_2x#{ext}"), prefix)
        end
        
        def width(name, prefix)
          exif(name, prefix).imagewidth
        end
        
        def height(name, prefix)
          exif(name, prefix).imageheight
        end
        
        def exif(name, prefix)
          @exif ||= MiniExiftool.new File.join("public", source(name, prefix))
        end
      end
    end
  end
end
