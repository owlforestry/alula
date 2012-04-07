module Alula
  module Plugins
    # def self.register(plugin, path)
    #   @@plugins ||= {}
    #   @@plugins[plugin] = path
    # end
    # 
    # def self.plugins
    #   @@plugins
    # end
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
  end
end
