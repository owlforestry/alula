require 'alula/core_ext/tag'
require 'mini_exiftool'
require 'hashie/mash'

module Alula
  class ImageTag < Tag
    def prepare
      @info = {}

      @options["classes"] ||= []
      @options["title"] ||= @options["alternative"]
      @options["alternative"] ||= @options["title"]
      @options["classes"] += [@options["align"]] || ["left"]
    end
    
    def content
      hires = hires_url(@source, :image)
      tag = "<a href=\"#{attachment_url(@source, :image)}\""
      tag += " data-hires=\"#{hires}\"" if context.site.config.attachments["image"]["hires"] and hires
      tag += ">"
      tag += imagetag(@source, :thumbnail)
      tag += "</a>"
    end
    
    def imagetag(source, type, opts = {})
      src = attachment_url(source, type)
      hires = hires_url(source, type)
      
      classes = opts.delete(:classes) || @options["classes"]
      
      tag = "<img"
      tag += " alt=\"#{@options["alternative"]}\"" if @options["alternative"]
      tag += " title=\"#{@options["title"]}\"" if @options["title"]
      tag += " class=\"#{classes.join(" ")}\""
      if context.site.config.attachments.image.lazyload
        tag += " src=\"#{asset_url("grey.gif")}\""
        tag += " data-original=\"#{src}\""
      else
        tag += " src=\"#{src}\""
      end
      tag += " data-hires=\"#{hires}\"" if context.site.config.attachments.image.hires and hires
      tag += " width=\"#{info(source, type).width}\" height=\"#{info(source, type).height}\""
      tag += " />"
    end
    
    private
    def hires_url(source, type)
      hires_source = source.gsub(/(#{File.extname(source)})$/, '-hires\1')
      attachment_url(hires_source, type)
    end
  end
end

Alula::Tag.register :image, Alula::ImageTag
