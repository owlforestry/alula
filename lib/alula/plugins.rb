module Alula
  module Plugins
    def self.register_attachment_handler(type, handler)
      @@handlers ||= {}
      @@handlers[:attachment] ||= {}
      @@handlers[:attachment][type] = handler
    end
    
    def self.attachment_handler(type)
      @@handlers ||= {}
      @@handlers[:attachment] ||= {}
      @@handlers[:attachment][type]
    end
    
    def self.register_content_for_head(content)
      @@content_for_head ||= ""
      if content.kind_of?(Array)
        @@content_for_head << content.join("\n")
      else
        @@content_for_head << content
      end
    end
    
    def self.content_for_head
      @@content_for_head ||= ""
    end
  end
end
