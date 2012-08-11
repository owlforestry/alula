require 'alula/core_ext/tags/image'
require 'alula/plugin'

module Alula
  class Fancybox < ImageTag
    def self.path
      File.join(File.dirname(__FILE__), %w{.. .. .. plugins fancybox})
    end
    
    def self.version
      Alula::Plugins::VERSION
    end
    
    def self.install(options)
      # Display license unless acknoledged
      unless options.kind_of?(Hash) and options['personal']
        puts <<-ENDOFNOTICE
    *** fancyBox
    Please note, that fancyBox is licensed under the therms of the
    Creative Commons Attribution-NonCommercial 3.0 License
    (http://creativecommons.org/licenses/by-nc/3.0/).

    If you would like to use fancyBox for commercial purposes,
    you can purchase a license from http://fancyapps.com/store/

    To remove this notice, please include following options in config.yml
    ---
    plugins:
      fancybox:
        personal: true
        ENDOFNOTICE
      end
      
      # Register for image tags
      Alula::Tag.register :image, self
    end
    
    def content
      # FeedBuilder support, skip sublime extensions for feeds
      return super if self.context.item.metadata.renderer.class.to_s == "Alula::FeedBuilder"
      
      image = attachment_url(@source, :image)
      thumbnail = attachment_url(@source, :thumbnail)
      hires = hires_url(@source, :image)
      info = info(@source, :image)
      tn_info = info(@source, :thumbnail)

      return super unless image and thumbnail
      
      tag = "<a"
      tag += " class=\"img fancybox fb_zoomable #{@options["classes"].join(" ")}\""
      tag += " href=\"#{image}\""
      tag += " data-width=\"#{info.width}\""
      tag += " data-height=\"#{info.height}\""
      tag += " data-hires=\"#{hires}\"" if context.site.config.attachments.image.hires and hires
      tag += " data-fancybox-group=\"#{context.item.id}\""
      tag += " title=\"#{@options["title"]}\"" if @options["title"]
      tag += " style=\"width: #{tn_info.width}px; height: #{tn_info.height}px;\""
      tag += ">"
      tag += imagetag(@source, :thumbnail, classes: [])
      tag += "  <span class=\"fb_zoom_icon\"></span>"
      tag += "</a>"
    end
  end
end

Alula::Plugin.register :fancybox, Alula::Fancybox
