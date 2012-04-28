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
          @align = "left"
          @classes = []
          
          /(?<src>(?:https?:\/\/|\/|\S+\/)[^"]+)(?:"|')?/ =~ markup
          @name = src.strip
        end
        
        def content(context)
          # Try to find all possible variant of video
          exif = MiniExiftool.new File.join("public", sources.first)
          tag = "<video"
          tag += " controls"
          tag += " class=\"#{(self.classes + [@align]).join(" ")}\""
          tag += " width=\"#{exif.imagewidth}\""
          tag += " height=\"#{exif.imageheight}\""
          tag += " poster=\"#{poster}\""
          tag += " preload=\"none\">"
          
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
        
        attr_accessor :prefix
        attr_reader :name, :prefix, :title, :classes
        
        def self.install(options)
          @@options = options
        end
        
        def prepare(markup, tokens)
          @classes = []
          @align = "left"
          
          /(?<src>\S+)( (?<options>.+))?/ =~ markup
          @src = src

          if options
            options.scan(/(\S+):["]?((?:.(?!["]?\s+(?:\S+):|[>"]))+.)["]?/) do |name, value|
              case name
              when "title"
                @title = value
                @alternative ||= value
              when "alt"
                @alternative = value
                @title ||= value
              when "align"
                @align = value
              end
            end
          end
        end
        
        def content(context)
          imagetag(@src)
        end
        
        def imagetag(name, prefix = nil)
          @name = name
          @prefix = prefix
          
          tag = "<img"
          tag += " alt=\"#{self.alternative}\"" if self.alternative
          tag += " title=\"#{self.title}\"" if self.title
          tag += " class=\"#{(self.classes + [@align]).join(" ")}\""
          if context.config.images["lazyload"]
            tag += " src=\"#{context.asset_url("grey.gif")}\""
            tag += " data-original=\"#{self.source(name, prefix)}\""
            tag += " data-hires=\"#{self.hires(name, prefix)}\"" if context.config.images["hires"] and self.hires(name, prefix)
          else
            tag += " src=\"#{self.source(name, prefix)}\""            
          end
          tag += " width=\"#{self.width}\" height=\"#{self.height}\""
          tag += " />"
        end
        
        def source(name = nil, prefix = nil)
          if name[/^http/]
            name
          else
            context.asset_url(prefix ? File.join(prefix, name) : name)
          end
        end
        
        def hires(name, prefix)
          ext = File.extname(name)
          source(name.gsub(/#{ext}$/, "_2x#{ext}"), prefix)
        end
        
        def width
          exif.imagewidth
        end
        
        def height
          exif.imageheight
        end
        
        def alternative
          @alternative# ||= self.title
        end
        
        def title
          @title# ||= exif.title
        end
        
        def exif
          @exif ||= MiniExiftool.new File.join(context.config.public_path, source(self.name, self.prefix))
        end
      end
    end
  end
end
