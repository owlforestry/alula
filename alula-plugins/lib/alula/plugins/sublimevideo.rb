require 'alula/core_ext/tags/video'
require 'alula/plugin'

module Alula
  class Sublimevideo < VideoTag
    def self.path
      File.join(File.dirname(__FILE__), %w{.. .. .. plugins sublimevideo})
    end
    
    def self.version
      Alula::Plugins::VERSION
    end
    
    def self.install(options)
      # Require valid sublime token present in configuration
      return false unless options.token
      
      # Register addons
      Alula::Plugin.addon :head, ->(context) {
        "<script src=\"http://cdn.sublimevideo.net/js/#{options.token}.js\" async></script>" if context.item.content[/\<video/]
      }
      
      # Register for image tags
      Alula::Tag.register :video, self
    end
    
    def content
      # FeedBuilder support, skip sublime extensions for feeds
      return super if self.context.item.metadata.renderer.class.to_s == "Alula::FeedBuilder"

      sublime_videotag(@source)
    end
    
    def sublime_videotag(source)
      poster = source.gsub(/#{File.extname(source)}$/, '.png')
      info = info(poster, :thumbnail)
      poster_hires = hires_url(poster, :thumbnail)
      poster = attachment_url(poster, :thumbnail)
      
      tag =  "<a"
      tag += " class=\"sublime zoomable\""
      tag += " href=\"#{sources.first[:url]}\""
      tag += " style=\"width: #{info.width}px; height: #{info.height}px;\""
      tag += ">"
      tag += " <img"
      tag += "  alt=\"#{@options["alternative"]}\""
      tag += "  width=\"#{info.width}\" height=\"#{info.height}\""
      if context.site.config.attachments.image.lazyload
        tag += " src=\"#{asset_url("grey.gif")}\""
        tag += " data-original=\"#{poster}\""
      else
        tag += " src=\"#{poster}\""
      end
      tag += " data-hires=\"#{poster_hires}\"" if context.site.config.attachments.image.hires and poster_hires
      
      tag += "  />"
      tag += "  <span class=\"zoom_icon\"></span>"
      tag += "</a>"
      
      info = info(sources.first[:name], :video)
      tag += "<video"
      tag += " controls"
      tag += " class=\"sublime lightbox\""
      tag += " style=\"display: none;\""
      tag += " width=\"#{info.width}\""
      tag += " height=\"#{info.height}\""
      tag += " poster=\"#{poster}\""
      tag += " preload=\"none\""
      tag += " data-uid=\"#{source}\""
      tag += " data-name=\"#{source}\""
      tag += ">"
      
      sources.each do |source|
        tag += "  <source src=\"#{source[:url]}\" #{source[:hires] ? "data-quality=\"hd\"" : ""} />"
      end
      
      tag += "</video>"
      
    end
  end
end

Alula::Plugin.register :sublimevideo, Alula::Sublimevideo
