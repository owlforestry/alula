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
    end
  end
end
