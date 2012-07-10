module Alula
  class ImageTag < Tag
    def prepare
      @classes = []
      @align = "left"
      
      if m = /(")?(?:(.+))\1(?: (.+))?/.match(@markup)
        @source = m[2]
        options = m[3]
      end
      
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
    
    def content
      imagetag(@source, :image)
    end
    
    def imagetag(source, type)
      name = File.join(type.to_s, source)
      asset_name = self.context.attachments.mapping[name]
      src = self.context.asset_url(asset_name)
      
      tag = "<img"
      # tag += " alt=\"#{self.alternative}\"" if self.alternative
      # tag += " title=\"#{self.title}\"" if self.title
      # tag += " class=\"#{(self.classes + [@align]).join(" ")}\""
      if context.site.config.attachments["image"]["lazyload"]
        tag += " src=\"#{context.asset_url("grey.gif")}\""
        tag += " data-original=\"#{src}\""
      else
        tag += " src=\"#{src}\""
      end
      # tag += " data-hires=\"#{self.hires}\"" if context.config.attachments["images"]["hires"] and self.hires
      # tag += " width=\"#{self.width}\" height=\"#{self.height}\""
      tag += " />"
    end
  end
end

Alula::Tag.register :image, Alula::ImageTag
