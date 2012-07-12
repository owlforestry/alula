module Alula
  class AttachmentTag < Tag
    def prepare
      @classes = []
      
      if m = /(["'])?([^"']+)\1?(?: (.+))?/.match(@markup)
        @source = m[2]
        @title = File.basename(@source)
        options = m[3]
      end
      
      if options
        options.scan(/(\S+):["]?((?:.(?!["]?\s+(?:\S+):|[>"]))+.)["]?/) do |name, value|
          case name
          when "title"
            @title = value
          end
        end
      end
    end
    
    def content
      "<a href=\"#{attachment_url(@source)}\">#{@title}</a>"
    end
  end
end

Alula::Tag.register :attachment, Alula::AttachmentTag
