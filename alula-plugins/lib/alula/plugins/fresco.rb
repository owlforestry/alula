require 'alula/core_ext/tags/image'
require 'alula/plugin'

module Alula
  class Fresco < ImageTag
    def self.path
      File.join(File.dirname(__FILE__), %w{.. .. .. plugins fresco})
    end
    
    def self.version
      Alula::Plugins::VERSION::STRING
    end
    
    def self.install(options)
      # Display license unless acknoledged
      unless options.kind_of?(Hash) and options['personal']
        puts <<-ENDOFNOTICE
    *** Fresco
    Fresco is licensed under the terms of the Fresco License.
    Usage on non-commercial websites is free.
    Licenses are available for commercial use.
    
    If you would like to use Fresco for commercial purposes,
    you can purchase a license from http://www.frescojs.com/download

    To remove this notice, please include following options in config.yml
    ---
    plugins:
      fresco:
        personal: true
        ENDOFNOTICE
      end
      
      @@options = options
      
      # Register for image tags
      Alula::Tag.register :image, self
    end
    
    def content
      # FeedBuilder support, skip sublime extensions for feeds
      return super if self.context.item.metadata.renderer.class.to_s[/FeedBuilder/]
      
      image = attachment_url(@source, :image)
      thumbnail = attachment_url(@source, :thumbnail)
      hires = hires_url(@source, :image)
      info = info(@source, :image)
      tn_info = info(@source, :thumbnail)

      return super unless image and thumbnail
      
      unless @options['alternative'] or @options['title']
        @options['title'] = info(@source, :image).title
        @options['alternative'] = info(@source, :image).title
      end
      
      tag = "<a"
      tag += " class=\"img fresco fb_zoomable #{@options["classes"].join(" ")}\""
      tag += " href=\"#{image}\""
      tag += " data-width=\"#{info.width}\""
      tag += " data-height=\"#{info.height}\""
      tag += " data-hires=\"#{hires}\"" if context.site.config.attachments.image.hires and hires
      tag += " data-fresco-group=\"#{context.item.id}\""
      tag += " data-fresco-group-options=\"ui: 'inside', thumbnails:#{@@options['thumbnails'] ? "true" : "false"}\""
      tag += " data-fresco-caption=\"#{@options['title']}\"" if @options["title"]
      tag += " title=\"#{@options["title"]}\"" if @options["title"]
      tag += " style=\"width: #{tn_info.width}px; height: #{tn_info.height}px;\""
      tag += ">"
      tag += imagetag(@source, :thumbnail, classes: [])
      tag += "  <span class=\"fb_zoom_icon\"></span>"
      tag += "</a>"
    end
  end
end

Alula::Plugin.register :fresco, Alula::Fresco
